import '../../../core/supabase/supabase_init.dart';
import '../../auth/models/profile.dart';
import '../../recycle/models/recycling_submission.dart';

class VolunteerRepository {
  Future<Profile> lookupByQrPayload(String payload) async {
    var token = payload.trim();
    if (token.startsWith('eco:')) token = token.substring(4);
    final row = await supabase.rpc('lookup_by_qr_token', params: {
      'p_token': token,
    });
    if (row is Map<String, dynamic>) {
      return Profile.fromJson(row);
    }
    throw StateError('Студент не найден');
  }

  Future<RecyclingSubmission> confirmDropoff({
    required String studentId,
    required String categoryId,
    required double weightKg,
    String? collectionPointId,
    double bonusMultiplier = 1,
  }) async {
    final row = await supabase.rpc('confirm_dropoff', params: {
      'p_student_id': studentId,
      'p_category_id': categoryId,
      'p_weight_kg': weightKg,
      'p_collection_point_id': collectionPointId,
      'p_bonus_multiplier': bonusMultiplier,
    });
    return RecyclingSubmission.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  Future<List<RecyclingSubmission>> fetchPendingClaims() async {
    final rows = await supabase
        .from('recycling_submissions')
        .select('*, waste_categories(fraction, name_ru)')
        .eq('status', 'pending')
        .eq('method', 'photo_claim')
        .order('submitted_at')
        .limit(50);
    return rows.map((e) => RecyclingSubmission.fromJson(e)).toList();
  }

  Future<RecyclingSubmission> moderate({
    required String submissionId,
    required bool approve,
    String? note,
  }) async {
    final row = await supabase.rpc('moderate_submission', params: {
      'p_submission_id': submissionId,
      'p_approve': approve,
      'p_reviewer_note': note,
    });
    return RecyclingSubmission.fromJson(
      Map<String, dynamic>.from(row as Map),
    );
  }

  Future<List<Map<String, dynamic>>> fetchPendingProofs() async {
    final rows = await supabase
        .from('challenge_proofs')
        .select('*, challenges(title)')
        .eq('status', 'pending')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> moderateProof({
    required String proofId,
    required bool approve,
    String? note,
  }) async {
    await supabase.from('challenge_proofs').update({
      'status': approve ? 'approved' : 'rejected',
      'reviewer_note': note,
    }).eq('id', proofId);
  }

  Future<void> updateRedeemStatus({
    required String id,
    required String status,
  }) async {
    await supabase.from('redeem_requests').update({'status': status}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchOpenBinReports() async {
    final rows = await supabase
        .from('bin_reports')
        .select('*, collection_points(name)')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
