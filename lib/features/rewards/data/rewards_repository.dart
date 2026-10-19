import '../../../core/supabase/supabase_init.dart';
import '../models/redeem_request.dart';
import '../models/reward_item.dart';

class RewardsRepository {
  Future<void> redeem(RewardItem reward) async {
    await supabase.rpc(
      'redeem_reward',
      params: {
        'p_reward_code': reward.code,
        'p_reward_title': reward.title,
        'p_points_cost': reward.pointsCost,
      },
    );
  }

  Future<List<RedeemRequest>> fetchHistory(String userId) async {
    final rows = await supabase
        .from('redeem_requests')
        .select()
        .eq('student_id', userId)
        .order('created_at', ascending: false)
        .limit(30);
    return rows.map((e) => RedeemRequest.fromJson(e)).toList();
  }
}