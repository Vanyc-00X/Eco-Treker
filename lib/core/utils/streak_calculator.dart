/// Считает текущую серию дней сдачи по датам submissions (локальное время).
///
/// Правила:
/// - день считается активным, если есть хотя бы одна сдача;
/// - если сегодня нет сдач, серия может продолжаться с вчера;
/// - иначе серия = 0.
int calculateStreakDays(Iterable<DateTime> submittedAt, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  final days = <DateTime>{};
  for (final dt in submittedAt) {
    final local = dt.toLocal();
    days.add(DateTime(local.year, local.month, local.day));
  }
  if (days.isEmpty) return 0;

  var cursor = days.contains(todayDate)
      ? todayDate
      : todayDate.subtract(const Duration(days: 1));

  if (!days.contains(cursor)) return 0;

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}