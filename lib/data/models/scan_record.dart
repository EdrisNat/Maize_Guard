import 'dart:convert';

class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.imagePath,
    required this.predictedLabel,
    required this.confidence,
    required this.timestamp,
    required this.classProbabilities,
    required this.modelVersion,
    required this.diseaseId,
    this.reportPath,
    this.qualityScore,
    this.farmerNotes,
  });

  final String id;
  final String imagePath;
  final String predictedLabel;
  final double confidence;
  final DateTime timestamp;
  final Map<String, double> classProbabilities;
  final String? reportPath;
  final String modelVersion;
  final double? qualityScore;
  final String diseaseId;
  final String? farmerNotes;

  ScanRecord copyWith({
    String? reportPath,
    String? farmerNotes,
  }) {
    return ScanRecord(
      id: id,
      imagePath: imagePath,
      predictedLabel: predictedLabel,
      confidence: confidence,
      timestamp: timestamp,
      classProbabilities: classProbabilities,
      reportPath: reportPath ?? this.reportPath,
      modelVersion: modelVersion,
      qualityScore: qualityScore,
      diseaseId: diseaseId,
      farmerNotes: farmerNotes ?? this.farmerNotes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'predicted_label': predictedLabel,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'class_probabilities': jsonEncode(classProbabilities),
      'report_path': reportPath,
      'model_version': modelVersion,
      'quality_score': qualityScore,
      'disease_id': diseaseId,
      'farmer_notes': farmerNotes,
    };
  }

  factory ScanRecord.fromMap(Map<String, Object?> map) {
    final decoded = jsonDecode(map['class_probabilities'] as String);
    final probabilities = <String, double>{};
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, value) {
        probabilities[key] = (value as num).toDouble();
      });
    }
    return ScanRecord(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      predictedLabel: map['predicted_label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      classProbabilities: probabilities,
      reportPath: map['report_path'] as String?,
      modelVersion: map['model_version'] as String? ?? 'legacy-model',
      qualityScore: (map['quality_score'] as num?)?.toDouble(),
      diseaseId: map['disease_id'] as String? ??
          (map['predicted_label'] as String).toLowerCase().replaceAll('_', ' '),
      farmerNotes: map['farmer_notes'] as String?,
    );
  }
}
