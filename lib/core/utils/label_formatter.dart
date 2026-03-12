class LabelFormatter {
  static String toDisplayLabel(String label) {
    final normalized = label
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return label;

    return normalized.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  static String normalizedKey(String label) {
    return label
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }
}
