import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:maize_leaf_prediction/core/services/model_config.dart';

class ImagePreprocessor {
  // Deterministic production preprocessing:
  // image -> resize(224x224) -> RGB -> float32 -> configurable normalization
  static Float32List toNormalizedFloatList(
    img.Image image,
    ModelConfig config,
  ) {
    final resized = img.copyResize(
      image,
      width: config.inputWidth,
      height: config.inputHeight,
      interpolation: img.Interpolation.linear,
    );

    final totalValues =
        config.inputWidth * config.inputHeight * config.channels;
    final output = Float32List(totalValues);
    var index = 0;

    for (var y = 0; y < config.inputHeight; y++) {
      for (var x = 0; x < config.inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        output[index++] = (pixel.r - config.inputMean) / config.inputStd;
        output[index++] = (pixel.g - config.inputMean) / config.inputStd;
        output[index++] = (pixel.b - config.inputMean) / config.inputStd;
      }
    }
    return output;
  }
}
