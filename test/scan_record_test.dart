import 'package:flutter_test/flutter_test.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';

void main() {
  test('legacy scan records still parse with fallback metadata', () {
    final record = ScanRecord.fromMap({
      'id': '1',
      'image_path': 'leaf.jpg',
      'predicted_label': 'Healthy',
      'confidence': 0.98,
      'timestamp': '2026-03-11T10:00:00.000',
      'class_probabilities': '{"Healthy":0.98,"Common_Rust":0.02}',
    });

    expect(record.modelVersion, 'legacy-model');
    expect(record.diseaseId, 'healthy');
    expect(record.reportPath, isNull);
  });
}
