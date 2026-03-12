class ImageQualityAssessment {
  const ImageQualityAssessment({
    required this.score,
    required this.brightnessScore,
    required this.contrastScore,
    required this.resolutionScore,
    required this.guidance,
  });

  final double score;
  final double brightnessScore;
  final double contrastScore;
  final double resolutionScore;
  final List<String> guidance;

  String get statusLabel {
    if (score >= 0.82) return 'Field ready';
    if (score >= 0.62) return 'Usable';
    return 'Needs a better scan';
  }

  factory ImageQualityAssessment.fromStoredScore(double? score) {
    final normalized = (score ?? 0.7).clamp(0.0, 1.0);
    return ImageQualityAssessment(
      score: normalized,
      brightnessScore: normalized,
      contrastScore: normalized,
      resolutionScore: normalized,
      guidance: normalized >= 0.62
          ? const [
              'Capture 2-3 leaves if symptoms are uneven across the field.'
            ]
          : const [
              'Move closer to one leaf.',
              'Use brighter natural light.',
              'Keep the phone steady before capturing.',
            ],
    );
  }
}
