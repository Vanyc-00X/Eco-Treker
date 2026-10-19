import '../../../core/supabase/supabase_init.dart';
import '../models/leaderboard_entry.dart';

enum LeaderboardTab { students, groups, faculties }

enum LeaderboardMetric { points, kg, co2, challenges }

enum LeaderboardPeriod { week, month, semester, year, all }

class LeaderboardRepository {
  DateTime? _from(LeaderboardPeriod period) {
    final now = DateTime.now().toUtc();
    return switch (period) {
      LeaderboardPeriod.week => now.subtract(const Duration(days: 7)),
      LeaderboardPeriod.month => now.subtract(const Duration(days: 30)),
      LeaderboardPeriod.semester => now.subtract(const Duration(days: 120)),
      LeaderboardPeriod.year => now.subtract(const Duration(days: 365)),
      LeaderboardPeriod.all => null,
    };
  }

  String _metricKey(LeaderboardMetric m) => switch (m) {
        LeaderboardMetric.points => 'points',
        LeaderboardMetric.kg => 'kg',
        LeaderboardMetric.co2 => 'co2',
        LeaderboardMetric.challenges => 'challenges',
      };

  Future<List<LeaderboardEntry>> fetch(
    LeaderboardTab tab, {
    LeaderboardMetric metric = LeaderboardMetric.points,
    LeaderboardPeriod period = LeaderboardPeriod.all,
    String? faculty,
    String? group,
    int? course,
  }) async {
    if (tab == LeaderboardTab.students) {
      try {
        final rows = await supabase.rpc(
          'leaderboard_students',
          params: {
            'p_metric': _metricKey(metric),
            'p_from': _from(period)?.toIso8601String(),
            'p_faculty': faculty,
            'p_group': group,
            'p_course': course,
          },
        );
        if (rows is List) {
          return rows.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return LeaderboardEntry(
              id: m['id'] as String,
              name: m['title'] as String? ?? 'Student',
              greenPoints: (m['score'] as num?)?.round() ?? 0,
              rank: (m['rank'] as num?)?.toInt() ?? 0,
              subtitle: m['subtitle'] as String?,
              totalKg: metric == LeaderboardMetric.kg
                  ? (m['score'] as num?)?.toDouble()
                  : null,
            );
          }).toList();
        }
      } catch (_) {
        // fallback to view
      }
    }

    switch (tab) {
      case LeaderboardTab.students:
        final rows = await supabase
            .from('leaderboard_students')
            .select()
            .order('rank')
            .limit(50);
        return rows.map(LeaderboardEntry.student).toList();
      case LeaderboardTab.groups:
        final rows = await supabase
            .from('leaderboard_groups')
            .select()
            .order('rank')
            .limit(50);
        return rows.map(LeaderboardEntry.group).toList();
      case LeaderboardTab.faculties:
        final rows = await supabase
            .from('leaderboard_faculties')
            .select()
            .order('rank')
            .limit(50);
        return rows.map(LeaderboardEntry.faculty).toList();
    }
  }
}
