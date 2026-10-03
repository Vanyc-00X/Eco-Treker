class CollectionPoint {
  const CollectionPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.workHours,
    required this.acceptedFractions,
    required this.isActive,
    this.description,
    this.fillPercent,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String workHours;
  final List<String> acceptedFractions;
  final bool isActive;
  final String? description;
  final int? fillPercent;

  factory CollectionPoint.fromJson(Map<String, dynamic> json) {
    final fractions = json['accepted_fractions'];
    return CollectionPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      workHours: json['work_hours'] as String? ?? '',
      acceptedFractions: fractions is List
          ? fractions.map((e) => e.toString()).toList()
          : const [],
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      fillPercent: (json['fill_percent'] as num?)?.toInt(),
    );
  }
}