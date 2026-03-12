import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:maize_leaf_prediction/core/utils/label_formatter.dart';
import 'package:maize_leaf_prediction/data/models/disease_definition.dart';

class DiseaseCatalog {
  const DiseaseCatalog({
    required this.catalogVersion,
    required this.modelVersion,
    required this.diseases,
    required this.aliasToDiseaseId,
  });

  final String catalogVersion;
  final String modelVersion;
  final Map<String, DiseaseDefinition> diseases;
  final Map<String, String> aliasToDiseaseId;

  List<DiseaseDefinition> get orderedDiseases {
    final items = diseases.values.toList(growable: false);
    items.sort((a, b) => a.displayName.compareTo(b.displayName));
    return items;
  }

  DiseaseDefinition resolveLabel(String label) {
    final normalized = LabelFormatter.normalizedKey(label);
    final diseaseId = aliasToDiseaseId[normalized];
    if (diseaseId != null && diseases.containsKey(diseaseId)) {
      return diseases[diseaseId]!;
    }

    return DiseaseDefinition(
      id: normalized.replaceAll(' ', '_'),
      displayName: LabelFormatter.toDisplayLabel(label),
      summary:
          'This class is available in the model but does not yet have a full local disease profile. Review field symptoms before taking action.',
      severity: 'unknown',
      symptoms: const [
        'Compare this leaf with nearby plants.',
        'Look for repeating symptom patterns across the field.',
      ],
      management: const [
        'Use this result as decision support only.',
        'Capture more images before making treatment decisions.',
      ],
      prevention: const [
        'Keep scouting and field notes up to date.',
      ],
      nextSteps: const [
        'Save the result in history.',
        'Share the PDF report with an agronomy advisor if needed.',
      ],
      labelAliases: [normalized],
      rescanAdvice:
          'Capture 2-3 clearer leaf images from different plants for a stronger comparison.',
      escalateWhen:
          'Escalate if symptoms are severe, spreading, or the crop is declining quickly.',
      lowLiteracyTip:
          'The app saw a pattern it knows, but this disease card still needs more local information.',
    );
  }
}

class DiseaseCatalogService {
  const DiseaseCatalogService(this._assetPath);

  final String _assetPath;

  Future<DiseaseCatalog> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawDiseases = decoded['diseases'] as List<dynamic>? ?? const [];

    final diseases = <String, DiseaseDefinition>{};
    final aliasMap = <String, String>{};

    for (final item in rawDiseases) {
      final disease = DiseaseDefinition.fromMap(item as Map<String, dynamic>);
      diseases[disease.id] = disease;

      for (final alias in disease.labelAliases) {
        aliasMap[LabelFormatter.normalizedKey(alias)] = disease.id;
      }
      aliasMap[LabelFormatter.normalizedKey(disease.displayName)] = disease.id;
    }

    return DiseaseCatalog(
      catalogVersion: decoded['catalogVersion'] as String? ?? 'unknown',
      modelVersion: decoded['modelVersion'] as String? ?? 'unknown',
      diseases: diseases,
      aliasToDiseaseId: aliasMap,
    );
  }
}
