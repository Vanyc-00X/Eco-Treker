import '../../../core/supabase/supabase_init.dart';
import '../models/leaderboard_entry.dart';

enum LeaderboardTab { students, groups, faculties }

class LeaderboardRepository {
  Future<List<LeaderboardEntry>> fetch(LeaderboardTab tab) async {
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