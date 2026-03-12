import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:maize_leaf_prediction/core/services/image_preprocessor.dart';
import 'package:maize_leaf_prediction/core/services/image_quality_service.dart';
import 'package:maize_leaf_prediction/core/services/model_config.dart';
import 'package:maize_leaf_prediction/data/models/prediction_result.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  TFLiteService(this._config) : _qualityService = const ImageQualityService();

  final ModelConfig _config;
  final ImageQualityService _qualityService;
  Interpreter? _interpreter;
  List<String> _labels = const [];
  bool _isInitialized = false;

  List<String> get labels => _labels;
  String get modelVersion => _config.modelVersion;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final rawLabels = await rootBundle.loadString(_config.labelsAssetPath);
    _labels = const LineSplitter()
        .convert(rawLabels)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (_labels.isEmpty) {
      throw Exception('Labels file is empty: ${_config.labelsAssetPath}');
    }

    _interpreter = await _createInterpreter();
    _logModelDiagnostics();
    _isInitialized = true;
  }

  Future<PredictionResult> runInference(String imagePath) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized.');
    }

    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('Image file not found.');
    }

    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unable to decode image.');
    }

    final qualityAssessment = _qualityService.assess(decoded);
    final raw = await _runDeterministicViews(decoded);
    final probabilities = _normalizeIfNeeded(raw);

    final classMap = <String, double>{};
    final classCount = _labels.isNotEmpty
        ? math.min(probabilities.length, _labels.length)
        : probabilities.length;
    if (classCount == 0) {
      throw Exception('No output classes available from inference result.');
    }
    for (var i = 0; i < classCount; i++) {
      final label = i < _labels.length ? _labels[i] : 'Class $i';
      classMap[label] = probabilities[i];
    }

    var bestLabel = classMap.entries.first.key;
    var bestConfidence = classMap.entries.first.value;
    for (final item in classMap.entries) {
      if (item.value > bestConfidence) {
        bestLabel = item.key;
        bestConfidence = item.value;
      }
    }

    return PredictionResult(
      predictedLabel: bestLabel,
      confidence: bestConfidence,
      classProbabilities: classMap,
      modelVersion: _config.modelVersion,
      qualityAssessment: qualityAssessment,
    );
  }

  Future<List<double>> _runDeterministicViews(img.Image decoded) async {
    final views = <img.Image>[decoded];

    if (_config.enableDeterministicTta) {
      views.add(_centerCrop(decoded, 0.85));
    }

    final accumulated = <double>[];
    for (final view in views) {
      final raw = _runSingleView(view);
      if (raw.isEmpty) {
        throw Exception('Inference produced empty output.');
      }
      if (accumulated.isEmpty) {
        accumulated.addAll(raw);
      } else {
        final length = math.min(accumulated.length, raw.length);
        for (var i = 0; i < length; i++) {
          accumulated[i] += raw[i];
        }
      }
    }

    for (var i = 0; i < accumulated.length; i++) {
      accumulated[i] /= views.length;
    }
    return accumulated;
  }

  List<double> _runSingleView(img.Image imageView) {
    final normalizedInput = ImagePreprocessor.toNormalizedFloatList(
      imageView,
      _config,
    );
    final input4d = _reshapeTo4D(
      normalizedInput,
      _config.inputHeight,
      _config.inputWidth,
      _config.channels,
    );

    final outputTensor = _interpreter!.getOutputTensor(0);
    final output = _createBufferFromShape(
      outputTensor.shape,
      _config.outputTensorType == OutputTensorType.uint8 ? 0 : 0.0,
    );
    _interpreter!.run(input4d, output);

    var raw = _flattenToDoubles(output);
    if (_config.outputTensorType == OutputTensorType.uint8 &&
        _config.dequantizeUint8Output) {
      raw = _dequantizeOutput(raw, outputTensor);
    }
    return raw;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  List<List<List<List<double>>>> _reshapeTo4D(
    List<double> values,
    int height,
    int width,
    int channels,
  ) {
    var index = 0;
    return [
      List.generate(height, (_) {
        return List.generate(width, (_) {
          return List.generate(channels, (_) => values[index++],
              growable: false);
        }, growable: false);
      }, growable: false),
    ];
  }

  dynamic _createBufferFromShape(
    List<int> shape,
    dynamic leafValue, [
    int depth = 0,
  ]) {
    if (shape.isEmpty) return leafValue;
    if (depth == shape.length - 1) {
      return List.filled(shape[depth], leafValue, growable: false);
    }
    return List.generate(
      shape[depth],
      (_) => _createBufferFromShape(shape, leafValue, depth + 1),
      growable: false,
    );
  }

  List<double> _flattenToDoubles(dynamic value) {
    final output = <double>[];
    void walk(dynamic node) {
      if (node is List) {
        for (final child in node) {
          walk(child);
        }
        return;
      }
      if (node is num) {
        output.add(node.toDouble());
      }
    }

    walk(value);
    return output;
  }

  Future<Interpreter> _createInterpreter() async {
    ByteData? loadedByteData;
    try {
      return await Interpreter.fromAsset(_config.modelAssetPath);
    } catch (assetError) {
      try {
        loadedByteData = await rootBundle.load(_config.modelAssetPath);
        final bytes = loadedByteData.buffer.asUint8List(
          loadedByteData.offsetInBytes,
          loadedByteData.lengthInBytes,
        );
        if (bytes.isEmpty) {
          throw Exception('Model asset is empty: ${_config.modelAssetPath}');
        }
        final signature = _readFlatBufferSignature(bytes);
        if (signature != 'TFL3') {
          throw Exception(
            'Invalid TensorFlow Lite FlatBuffer signature "$signature" for ${_config.modelAssetPath}. Expected "TFL3".',
          );
        }
        return Interpreter.fromBuffer(bytes);
      } catch (bufferError) {
        final modelInfo = _describeModelBytes(loadedByteData);
        throw Exception(
          'Unable to create interpreter. Verify the .tflite file is valid and built for TensorFlow Lite. Asset load error: $assetError | Buffer load error: $bufferError | $modelInfo Likely cause: unsupported/custom ops or incompatible op versions. Re-export model as TensorFlow Lite with builtin ops only (no Select TF Ops/Flex).',
        );
      }
    }
  }

  String _readFlatBufferSignature(Uint8List bytes) {
    if (bytes.length < 8) return 'too_short';
    return ascii.decode(bytes.sublist(4, 8), allowInvalid: true);
  }

  String _describeModelBytes(ByteData? byteData) {
    if (byteData == null) return 'model-bytes: unavailable';
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final signature = _readFlatBufferSignature(bytes);
    return 'model-bytes: size=${bytes.lengthInBytes}, signature=$signature';
  }

  List<double> _dequantizeOutput(List<double> rawValues, Tensor outputTensor) {
    try {
      final params = outputTensor.params;
      final scale = params.scale;
      final zeroPoint = params.zeroPoint;
      if (scale == 0) return rawValues;
      return rawValues.map((v) => (v - zeroPoint) * scale).toList();
    } catch (_) {
      return rawValues.map((v) => v / 255.0).toList();
    }
  }

  List<double> _normalizeIfNeeded(List<double> values) {
    if (values.isEmpty) return values;
    final sum = values.fold<double>(0, (acc, v) => acc + v);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    final alreadyProbabilities =
        minValue >= 0 && maxValue <= 1 && (sum - 1.0).abs() < 0.02;
    if (alreadyProbabilities) return values;

    final shifted = minValue < 0
        ? values.map((v) => v - minValue).toList(growable: false)
        : values;
    final shiftedSum = shifted.fold<double>(0, (acc, v) => acc + v);
    if (shiftedSum > 0) {
      return shifted.map((v) => (v / shiftedSum).clamp(0.0, 1.0)).toList();
    }
    return List.filled(values.length, 1.0 / values.length);
  }

  img.Image _centerCrop(img.Image source, double fraction) {
    final cropW = (source.width * fraction).round().clamp(1, source.width);
    final cropH = (source.height * fraction).round().clamp(1, source.height);
    final left = ((source.width - cropW) / 2).round();
    final top = ((source.height - cropH) / 2).round();
    return img.copyCrop(
      source,
      x: left,
      y: top,
      width: cropW,
      height: cropH,
    );
  }

  void _logModelDiagnostics() {
    if (!_config.enableModelDiagnostics || _interpreter == null) return;
    try {
      final input = _interpreter!.getInputTensor(0);
      final output = _interpreter!.getOutputTensor(0);
      debugPrint(
        '[TFLite] input shape=${input.shape} type=${input.type}; output shape=${output.shape} type=${output.type} quant(scale=${output.params.scale}, zeroPoint=${output.params.zeroPoint})',
      );
      debugPrint(
        '[TFLite] config: version=${_config.modelVersion}, preprocessing=resize_to_${_config.inputWidth}x${_config.inputHeight}_rgb_((x-${_config.inputMean})/${_config.inputStd}), outputTensorType=${_config.outputTensorType}, dequantizeUint8Output=${_config.dequantizeUint8Output}, enableDeterministicTta=${_config.enableDeterministicTta}',
      );
    } catch (_) {
      // Diagnostics are helpful but non-fatal.
    }
  }
}
