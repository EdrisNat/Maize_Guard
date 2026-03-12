import 'package:maize_leaf_prediction/core/utils/label_formatter.dart';

class ResultTexts {
  static String guidanceForLabel(String label) {
    switch (LabelFormatter.normalizedKey(label)) {
      case 'northern leaf blight':
        return 'Likely Northern Leaf Blight. Isolate affected plants and consult local agronomy guidance for fungicide timing.';
      case 'common rust':
        return 'Likely Common Rust. Monitor spread and consider integrated disease management based on growth stage.';
      case 'gray leaf spot':
        return 'Likely Gray Leaf Spot. Improve airflow and monitor moisture conditions in the field.';
      case 'maize lethal necrosis':
        return 'Likely Maize Lethal Necrosis. Remove severely affected plants, control vectors, and consult local extension guidance urgently.';
      case 'maize streak virus':
        return 'Likely Maize Streak Virus. Rogue infected plants where feasible and strengthen early vector management and field hygiene.';
      case 'healthy':
        return 'Leaf appears healthy. Continue routine monitoring and keep field records.';
      default:
        return 'Review this result with field observations before making treatment decisions.';
    }
  }
}
