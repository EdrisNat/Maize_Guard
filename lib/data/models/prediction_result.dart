import 'package:maize_leaf_prediction/data/models/image_quality_assessment.dart';

class PredictionResult {
  const PredictionResult({
    required this.predictedLabel,
    required this.confidence,
    required this.classProbabilities,
    required this.modelVersion,
    required this.qualityAssessment,
  });

  final String predictedLabel;
  final double confidence;
  final Map<String, double> classProbabilities;
  final String modelVersion;
  final ImageQualityAssessment qualityAssessment;
}
