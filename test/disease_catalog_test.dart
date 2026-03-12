import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maize_leaf_prediction/core/utils/label_formatter.dart';
import 'package:maize_leaf_prediction/data/models/disease_definition.dart';

void main() {
  test('disease catalog aliases normalize across label shapes', () {
    final disease = DiseaseDefinition.fromMap({
      'id': 'gray_leaf_spot',
      'displayName': 'Gray Leaf Spot',
      'summary': 'summary',
      'severity': 'high',
      'symptoms': ['lesions'],
      'management': ['monitor'],
      'prevention': ['rotate'],
      'nextSteps': ['scan more'],
      'labelAliases': ['Gray_Leaf_Spot', 'gray leaf spot'],
      'rescanAdvice': 'rescan',
      'escalateWhen': 'escalate',
      'lowLiteracyTip': 'tip',
    });

    final aliases = disease.labelAliases.map(LabelFormatter.normalizedKey).toSet();
    expect(aliases, contains('gray leaf spot'));
    expect(jsonEncode(disease.labelAliases), contains('Gray_Leaf_Spot'));
  });
}
