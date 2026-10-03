class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.ecoLevel,
    required this.greenPoints,
    required this.totalKg,
    required this.co2SavedKg,
    this.avatarUrl,
    this.qrToken,
    this.facultyId,
    this.groupId,
    this.course,
    this.phone,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String ecoLevel;
  final int greenPoints;
  final double totalKg;
  final double co2SavedKg;
  final String? avatarUrl;
  final String? qrToken;
  final String? facultyId;
  final String? groupId;
  final int? course;
  final String? phone;

  String get ecoLevelLabel {
    switch (ecoLevel) {
      case 'forest_keeper':
        return 'Forest Keeper';
      case 'eco_master':
        return 'Eco Master';
      default:
        return 'Eco Novice';
    }
  }

  int get ecoLevelNumber {
    switch (ecoLevel) {
      case 'forest_keeper':
        return 2;
      case 'eco_master':
        return 3;
      default:
        return 1;
    }
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Student',
      role: json['role'] as String? ?? 'student',
      ecoLevel: json['eco_level'] as String? ?? 'eco_novice',
      greenPoints: (json['green_points'] as num?)?.toInt() ?? 0,
      totalKg: (json['total_kg'] as num?)?.toDouble() ?? 0,
      co2SavedKg: (json['co2_saved_kg'] as num?)?.toDouble() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      qrToken: json['qr_token'] as String?,
      facultyId: json['faculty_id'] as String?,
      groupId: json['group_id'] as String?,
      course: (json['course'] as num?)?.toInt(),
      phone: json['phone'] as String?,
    );
  }
}