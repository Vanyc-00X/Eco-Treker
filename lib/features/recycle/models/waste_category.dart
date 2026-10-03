class WasteCategory {
  const WasteCategory({
    required this.id,
    required this.fraction,
    required this.nameRu,
    required this.pointsPerKg,
    required this.co2PerKg,
  });

  final String id;
  final String fraction;
  final String nameRu;
  final int pointsPerKg;
  final double co2PerKg;

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id'] as String,
      fraction: json['fraction'] as String,
      nameRu: json['name_ru'] as String? ?? json['fraction'] as String,
      pointsPerKg: (json['points_per_kg'] as num?)?.toInt() ?? 0,
      co2PerKg: (json['co2_per_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}