import '../../../core/supabase/supabase_init.dart';
import '../models/challenge.dart';

class ChallengesRepository {
  Future<List<Challenge>> fetchChallenges() async {
    final rows = await supabase
        .from('challenges')
        .select()
        .eq('is_published', true)
        .order('ends_at');
    return rows.map((e) => Challenge.fromJson(e)).toList();
  }

  Future<List<ChallengeParticipation>> fetchParticipations(String userId) async {
    final rows = await supabase
        .from('challenge_participations')
        .select()
        .eq('user_id', userId);
    return rows.map((e) => ChallengeParticipation.fromJson(e)).toList();
  }

  Future<List<Achievement>> fetchUserAchievements(String userId) async {
    final rows = await supabase
        .from('user_achievements')
        .select('earned_at, achievements(*)')
        .eq('user_id', userId)
        .order('earned_at', ascending: false);
    return rows.map((e) => Achievement.fromJson(e)).toList();
  }

  Future<void> joinChallenge({
    required String challengeId,
    required String userId,
  }) async {
    await supabase.from('challenge_participations').upsert({
      'challenge_id': challengeId,
      'user_id': userId,
      'status': 'active',
      'progress_kg': 0,
    });
  }
}