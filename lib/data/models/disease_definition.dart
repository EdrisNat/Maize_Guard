class DiseaseDefinition {
  const DiseaseDefinition({
    required this.id,
    required this.displayName,
    required this.summary,
    required this.severity,
    required this.symptoms,
    required this.management,
    required this.prevention,
    required this.nextSteps,
    required this.labelAliases,
    required this.rescanAdvice,
    required this.escalateWhen,
    required this.lowLiteracyTip,
    this.scientificName,
  });

  final String id;
  final String displayName;
  final String summary;
  final String severity;
  final List<String> symptoms;
  final List<String> management;
  final List<String> prevention;
  final List<String> nextSteps;
  final List<String> labelAliases;
  final String rescanAdvice;
  final String escalateWhen;
  final String lowLiteracyTip;
  final String? scientificName;

  factory DiseaseDefinition.fromMap(Map<String, dynamic> map) {
    List<String> readList(String key) {
      final raw = map[key];
      if (raw is List) {
        return raw.map((item) => item.toString()).toList(growable: false);
      }
      return const [];
    }

    return DiseaseDefinition(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      summary: map['summary'] as String,
      severity: map['severity'] as String? ?? 'moderate',
      symptoms: readList('symptoms'),
      management: readList('management'),
      prevention: readList('prevention'),
      nextSteps: readList('nextSteps'),
      labelAliases: readList('labelAliases'),
      rescanAdvice: map['rescanAdvice'] as String? ??
          'Capture a clearer close-up of a single leaf and compare again.',
      escalateWhen: map['escalateWhen'] as String? ??
          'Seek local agronomy guidance if symptoms keep spreading rapidly.',
      lowLiteracyTip: map['lowLiteracyTip'] as String? ??
          'Check more leaves before treating the field.',
      scientificName: map['scientificName'] as String?,
    );
  }
}
