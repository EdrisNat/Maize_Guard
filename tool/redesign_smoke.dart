import 'dart:convert';
import 'dart:io';

import 'package:maize_leaf_prediction/core/utils/label_formatter.dart';
import 'package:maize_leaf_prediction/data/models/disease_definition.dart';
import 'package:maize_leaf_prediction/data/models/scan_record.dart';

void main() {
  final catalogFile = File('assets/config/disease_catalog.json');
  final catalogJson = jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
  final diseases = (catalogJson['diseases'] as List<dynamic>)
      .map((item) => DiseaseDefinition.fromMap(item as Map<String, dynamic>))
      .toList(growable: false);

  if (diseases.length < 5) {
    stderr.writeln('Expected at least 5 diseases in the local catalog.');
    exitCode = 1;
    return;
  }

  final aliases = diseases.expand((item) => item.labelAliases).map(LabelFormatter.normalizedKey).toSet();
  if (!aliases.contains('common rust') || !aliases.contains('northern leaf blight')) {
    stderr.writeln('Catalog aliases are missing expected normalized disease labels.');
    exitCode = 1;
    return;
  }

  final legacyRecord = ScanRecord.fromMap({
    'id': 'legacy',
    'image_path': 'leaf.jpg',
    'predicted_label': 'Common_Rust',
    'confidence': 0.77,
    'timestamp': '2026-03-11T10:00:00.000',
    'class_probabilities': '{"Common_Rust":0.77}',
  });

  if (legacyRecord.modelVersion != 'legacy-model' || legacyRecord.diseaseId != 'common rust') {
    stderr.writeln('Legacy record fallback parsing failed.');
    exitCode = 1;
    return;
  }

  stdout.writeln('Redesign smoke checks passed.');
}
