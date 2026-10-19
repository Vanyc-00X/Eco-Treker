class RecyclingSubmission {
  const RecyclingSubmission({
    required this.id,
    required this.studentId,
    required this.categoryId,
    required this.method,
    required this.status,
    required this.weightKg,
    required this.pointsAwarded,
    required this.co2SavedKg,
    required this.submittedAt,
    this.photoUrl,
    this.note,
    this.fraction,
    this.categoryName,
  });

  final String id;
  final String studentId;
  final String categoryId;
  final String method;
  final String status;
  final double weightKg;
  final int pointsAwarded;
  final double co2SavedKg;
  final DateTime submittedAt;
  final String? photoUrl;
  final String? note;
  final String? fraction;
  final String? categoryName;

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';

  factory RecyclingSubmission.fromJson(Map<String, dynamic> json) {
    final category = json['waste_categories'];
    return RecyclingSubmission(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      categoryId: json['category_id'] as String,
      method: json['method'] as String? ?? 'photo_claim',
      status: json['status'] as String? ?? 'pending',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
      pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      co2SavedKg: (json['co2_awarded'] as num?)?.toDouble() ??
          (json['co2_saved_kg'] as num?)?.toDouble() ??
          0,
      submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? '') ??
          DateTime.now(),
      photoUrl: json['photo_url'] as String?,
      note: json['note'] as String?,
      fraction: category is Map ? category['fraction'] as String? : null,
      categoryName: category is Map ? category['name_ru'] as String? : null,
    );
  }
}