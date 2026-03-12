class FarmerProfile {
  const FarmerProfile({
    required this.name,
    required this.location,
    required this.languageCode,
    required this.lowLiteracyMode,
    this.pdfSavePath,
  });

  final String name;
  final String location;
  final String languageCode;
  final bool lowLiteracyMode;
  final String? pdfSavePath;

  FarmerProfile copyWith({
    String? name,
    String? location,
    String? languageCode,
    bool? lowLiteracyMode,
    String? pdfSavePath,
    bool clearPdfSavePath = false,
  }) {
    return FarmerProfile(
      name: name ?? this.name,
      location: location ?? this.location,
      languageCode: languageCode ?? this.languageCode,
      lowLiteracyMode: lowLiteracyMode ?? this.lowLiteracyMode,
      pdfSavePath: clearPdfSavePath ? null : (pdfSavePath ?? this.pdfSavePath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'languageCode': languageCode,
      'lowLiteracyMode': lowLiteracyMode,
      'pdfSavePath': pdfSavePath,
    };
  }

  factory FarmerProfile.fromMap(Map<String, dynamic> map) {
    return FarmerProfile(
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      lowLiteracyMode: map['lowLiteracyMode'] as bool? ?? false,
      pdfSavePath: map['pdfSavePath'] as String?,
    );
  }
}
