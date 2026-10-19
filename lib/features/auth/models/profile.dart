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
    this.facultyName,
    this.groupName,
    this.course,
    this.phone,
    this.dateOfBirth,
    this.verified = false,
    this.lastActiveAt,
    this.profileVisibility = 'public',
    this.showInLeaderboard = true,
    this.accentColor = 'green',
    this.mfaEnabled = false,
    this.deletedAt,
    this.notificationPrefs = const {},
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
  final String? facultyName;
  final String? groupName;
  final int? course;
  final String? phone;
  final DateTime? dateOfBirth;
  final bool verified;
  final DateTime? lastActiveAt;
  final String profileVisibility;
  final bool showInLeaderboard;
  final String accentColor;
  final bool mfaEnabled;
  final DateTime? deletedAt;
  final Map<String, dynamic> notificationPrefs;

  bool get isStudent => role == 'student';
  bool get isVolunteer => role == 'volunteer';
  bool get isAdmin => role == 'admin';
  bool get isStaff => isVolunteer || isAdmin;

  String get ecoLevelLabel {
    switch (ecoLevel) {
      case 'forest_keeper':
        return 'Хранитель леса';
      case 'eco_master':
        return 'Эко-магистр';
      default:
        return 'Эко-новичок';
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

  /// Прогресс 0..1 до следующего уровня (по кг).
  double get levelProgress {
    if (totalKg >= 100) return 1;
    if (totalKg >= 50) return ((totalKg - 50) / 50).clamp(0.0, 1.0);
    return (totalKg / 50).clamp(0.0, 1.0);
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    final rawDob = json['date_of_birth'];
    if (rawDob is String) dob = DateTime.tryParse(rawDob);

    DateTime? lastActive;
    final rawLa = json['last_active_at'];
    if (rawLa is String) lastActive = DateTime.tryParse(rawLa);

    DateTime? deleted;
    final rawDel = json['deleted_at'];
    if (rawDel is String) deleted = DateTime.tryParse(rawDel);

    final prefs = json['notification_prefs'];
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
      facultyName: json['faculty_name'] as String?,
      groupName: json['group_name'] as String?,
      course: (json['course'] as num?)?.toInt(),
      phone: json['phone'] as String?,
      dateOfBirth: dob,
      verified: json['verified'] as bool? ?? false,
      lastActiveAt: lastActive,
      profileVisibility: json['profile_visibility'] as String? ?? 'public',
      showInLeaderboard: json['show_in_leaderboard'] as bool? ?? true,
      accentColor: json['accent_color'] as String? ?? 'green',
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      deletedAt: deleted,
      notificationPrefs: prefs is Map<String, dynamic>
          ? prefs
          : const <String, dynamic>{},
    );
  }
}
