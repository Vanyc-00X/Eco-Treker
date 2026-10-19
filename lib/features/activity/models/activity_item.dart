enum ActivityKind { deposit, redeem, report }

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
    this.points,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final DateTime at;
  final int? points;
}