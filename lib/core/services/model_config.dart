enum OutputTensorType { float32, uint8 }

class ModelConfig {
  const ModelConfig({
    required this.modelAssetPath,
    required this.labelsAssetPath,
    required this.modelVersion,
    required this.diseaseCatalogAssetPath,
    this.inputWidth = 224,
    this.inputHeight = 224,
    this.channels = 3,
    this.outputTensorType = OutputTensorType.float32,
    this.inputMean = 0.0,
    this.inputStd = 255.0,
    this.dequantizeUint8Output = true,
    this.enableDeterministicTta = false,
    this.enableModelDiagnostics = true,
    this.confidenceThreshold,
  });

  final int inputWidth;
  final int inputHeight;
  final int channels;
  final String labelsAssetPath;
  final String modelAssetPath;
  final String modelVersion;
  final String diseaseCatalogAssetPath;
  final OutputTensorType outputTensorType;
  final double inputMean;
  final double inputStd;
  final bool dequantizeUint8Output;
  final bool enableDeterministicTta;
  final bool enableModelDiagnostics;
  final double? confidenceThreshold;
}
