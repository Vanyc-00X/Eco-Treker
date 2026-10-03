class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.rewardPoints,
    required this.startsAt,
    required this.endsAt,
    this.targetFraction,
    this.targetKg,
  });

  final String id;
  final String title;
  final String description;
  final String challengeType;
  final int rewardPoints;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? targetFraction;
  final double? targetKg;

  String get typeLabel {
    switch (challengeType) {
      case 'team':
        return 'Faculty Team';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      default:
        return 'Individual';
    }
  }

  Duration get timeLeft {
    final left = endsAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String get timeLeftLabel {
    final d = timeLeft;
    if (d.inDays > 0) return '${d.inDays}d left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      challengeType: json['challenge_type'] as String? ?? 'individual',
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? '') ??
          DateTime.now(),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      targetFraction: json['target_fraction'] as String?,
      targetKg: (json['target_kg'] as num?)?.toDouble(),
    );
  }
}

class ChallengeParticipation {
  const ChallengeParticipation({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.status,
    required this.progressKg,
    this.proofPhotoUrl,
    this.joinedAt,
    this.completedAt,
  });

  final String id;
  final String challengeId;
  final String userId;
  final String status;
  final double progressKg;
  final String? proofPhotoUrl;
  final DateTime? joinedAt;
  final DateTime? completedAt;

  factory ChallengeParticipation.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipation(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'active',
      progressKg: (json['progress_kg'] as num?)?.toDouble() ?? 0,
      proofPhotoUrl: json['proof_photo_url'] as String?,
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? ''),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    );
  }
}

class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.iconUrl,
    this.earnedAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String? iconUrl;
  final DateTime? earnedAt;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final nested = json['achievements'];
    if (nested is Map<String, dynamic>) {
      return Achievement(
        id: nested['id'] as String,
        code: nested['code'] as String? ?? '',
        title: nested['title'] as String? ?? 'Badge',
        description: nested['description'] as String? ?? '',
        iconUrl: nested['icon_url'] as String?,
        earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
      );
    }
    return Achievement(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? 'Badge',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
    );
  }
}