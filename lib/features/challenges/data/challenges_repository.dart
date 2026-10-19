import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<Achievement>> fetchAchievementCatalog() async {
    final rows = await supabase.from('achievements').select().order('code');
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

  Future<void> abandonChallenge(String challengeId) async {
    try {
      await supabase.rpc('abandon_challenge', params: {
        'p_challenge_id': challengeId,
      });
    } catch (_) {
      await supabase.from('challenge_participations').update({
        'status': 'abandoned',
        'abandoned_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('challenge_id', challengeId).eq('user_id', supabase.auth.currentUser!.id);
    }
  }

  Future<void> uploadProof({
    required String challengeId,
    required String userId,
    required Uint8List bytes,
    required String ext,
    String? comment,
  }) async {
    final path =
        'proofs/$userId/${challengeId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage.from('submissions').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
        );
    final url = supabase.storage.from('submissions').getPublicUrl(path);
    await supabase.from('challenge_proofs').insert({
      'challenge_id': challengeId,
      'user_id': userId,
      'photo_url': url,
      'comment': comment,
      'status': 'pending',
    });
  }

  Future<void> adminUpsertChallenge(Map<String, dynamic> data) async {
    if (data['id'] != null) {
      await supabase.from('challenges').update(data).eq('id', data['id']);
    } else {
      await supabase.from('challenges').insert(data);
    }
  }

  Future<void> adminDeleteChallenge(String id) async {
    await supabase.from('challenges').delete().eq('id', id);
  }
}
