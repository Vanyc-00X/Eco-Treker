import 'package:flutter/material.dart';

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
    this.photoUrl,
    this.contactPhone,
    this.contactName,
    this.isAccessible = false,
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
  final String? photoUrl;
  final String? contactPhone;
  final String? contactName;
  final bool isAccessible;

  /// Цвет маркера по основной фракции (ТЗ).
  Color get markerColor {
    final f = acceptedFractions.isEmpty ? '' : acceptedFractions.first;
    return switch (f) {
      'plastic' => const Color(0xFF2563EB),
      'paper' => const Color(0xFFEAB308),
      'glass' => const Color(0xFF16A34A),
      'metal' => const Color(0xFF6B7280),
      'hazardous' => const Color(0xFFDC2626),
      _ => const Color(0xFF2D6A4F),
    };
  }

  factory CollectionPoint.fromJson(Map<String, dynamic> json) {
    final fractions = json['accepted_fractions'];
    return CollectionPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      workHours: json['work_hours'] as String? ??
          json['open_hours'] as String? ??
          '',
      acceptedFractions: fractions is List
          ? fractions.map((e) => e.toString()).toList()
          : const [],
      isActive: json['is_active'] as bool? ?? true,
      description: json['description'] as String?,
      fillPercent: (json['fill_percent'] as num?)?.toInt(),
      photoUrl: json['photo_url'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactName: json['contact_name'] as String?,
      isAccessible: json['is_accessible'] as bool? ?? false,
    );
  }
}
