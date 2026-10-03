class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.greenPoints,
    required this.rank,
    this.subtitle,
    this.totalKg,
  });

  final String id;
  final String name;
  final int greenPoints;
  final int rank;
  final String? subtitle;
  final double? totalKg;

  factory LeaderboardEntry.student(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? 'Student',
      greenPoints: (json['green_points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      subtitle: [
        json['group_name'],
        json['faculty_short'],
      ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
      totalKg: (json['total_kg'] as num?)?.toDouble(),
    );
  }

  factory LeaderboardEntry.group(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Group',
      greenPoints: (json['green_points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      subtitle: json['faculty_short'] as String?,
      totalKg: (json['total_kg'] as num?)?.toDouble(),
    );
  }

  factory LeaderboardEntry.faculty(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Faculty',
      greenPoints: (json['green_points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      subtitle: json['short_name'] as String?,
      totalKg: (json['total_kg'] as num?)?.toDouble(),
    );
  }
}