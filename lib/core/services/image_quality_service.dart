import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:maize_leaf_prediction/data/models/image_quality_assessment.dart';

class ImageQualityService {
  const ImageQualityService();

  ImageQualityAssessment assess(img.Image image) {
    final totalPixels = image.width * image.height;
    final resolutionScore = (totalPixels / (1280 * 720)).clamp(0.35, 1.0);

    var luminanceSum = 0.0;
    var contrastAccumulator = 0.0;
    final samples = math.max(1, (image.width * image.height / 2500).round());
    final stepX = math.max(1, (image.width / math.sqrt(samples)).round());
    final stepY = math.max(1, (image.height / math.sqrt(samples)).round());
    final values = <double>[];

    for (var y = 0; y < image.height; y += stepY) {
      for (var x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        final luminance =
            (pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114);
        values.add(luminance);
        luminanceSum += luminance;
      }
    }

    final mean = values.isEmpty ? 128.0 : luminanceSum / values.length;
    for (final value in values) {
      final diff = value - mean;
      contrastAccumulator += diff * diff;
    }
    final contrastStd =
        values.isEmpty ? 0.0 : math.sqrt(contrastAccumulator / values.length);

    final brightnessScore =
        (1 - ((mean / 255.0) - 0.55).abs() / 0.55).clamp(0.15, 1.0);
    final contrastScore = (contrastStd / 64.0).clamp(0.15, 1.0);
    final totalScore = ((resolutionScore * 0.25) +
            (brightnessScore * 0.35) +
            (contrastScore * 0.40))
        .clamp(0.0, 1.0);

    final guidance = <String>[];
    if (brightnessScore < 0.55) {
      guidance.add('Use brighter natural light and avoid strong shadows.');
    }
    if (contrastScore < 0.55) {
      guidance.add('Hold the phone steady and focus on one clear lesion area.');
    }
    if (resolutionScore < 0.6) {
      guidance.add('Move closer so the leaf fills more of the frame.');
    }
    if (guidance.isEmpty) {
      guidance
          .add('Good capture quality. Still compare 2-3 leaves before acting.');
    }

    return ImageQualityAssessment(
      score: totalScore,
      brightnessScore: brightnessScore,
      contrastScore: contrastScore,
      resolutionScore: resolutionScore,
      guidance: guidance,
    );
  }
}
