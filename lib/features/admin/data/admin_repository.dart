import '../../../core/supabase/supabase_init.dart';

class AdminRepository {
  Future<Map<String, num>> fetchAnalytics() async {
    final profiles = await supabase
        .from('profiles')
        .select('green_points, total_kg, co2_saved_kg')
        .eq('role', 'student')
        .isFilter('deleted_at', null);
    var points = 0;
    var kg = 0.0;
    var co2 = 0.0;
    for (final p in profiles) {
      points += (p['green_points'] as num?)?.toInt() ?? 0;
      kg += (p['total_kg'] as num?)?.toDouble() ?? 0;
      co2 += (p['co2_saved_kg'] as num?)?.toDouble() ?? 0;
    }
    final pending = await supabase
        .from('recycling_submissions')
        .select('id')
        .eq('status', 'pending');
    return {
      'points': points,
      'kg': kg,
      'co2': co2,
      'pending': pending.length,
      'students': profiles.length,
    };
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final rows = await supabase
        .from('profiles')
        .select()
        .isFilter('deleted_at', null)
        .order('full_name')
        .limit(200);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> setUserRole(String userId, String role) async {
    await supabase.from('profiles').update({'role': role}).eq('id', userId);
  }

  Future<void> setVerified(String userId, bool verified) async {
    await supabase
        .from('profiles')
        .update({'verified': verified}).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> fetchChallengesRaw() async {
    final rows = await supabase.from('challenges').select().order('ends_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> saveChallenge(Map<String, dynamic> data) async {
    if (data['id'] != null) {
      final id = data.remove('id');
      await supabase.from('challenges').update(data).eq('id', id);
    } else {
      await supabase.from('challenges').insert(data);
    }
  }

  Future<void> deleteChallenge(String id) async {
    await supabase.from('challenges').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchPoints() async {
    final rows =
        await supabase.from('collection_points').select().order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> savePoint(Map<String, dynamic> data) async {
    if (data['id'] != null) {
      final id = data.remove('id');
      await supabase.from('collection_points').update(data).eq('id', id);
    } else {
      await supabase.from('collection_points').insert(data);
    }
  }

  Future<void> deletePoint(String id) async {
    await supabase.from('collection_points').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchRedeemRequests() async {
    final rows = await supabase
        .from('redeem_requests')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> setRedeemStatus(String id, String status) async {
    await supabase
        .from('redeem_requests')
        .update({'status': status}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchBinReports() async {
    final rows = await supabase
        .from('bin_reports')
        .select('*, collection_points(name)')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> setBinReportStatus(String id, String status) async {
    await supabase.from('bin_reports').update({'status': status}).eq('id', id);
  }

  String analyticsToCsv(Map<String, num> a) {
    return 'metric,value\n'
        'students,${a['students']}\n'
        'points,${a['points']}\n'
        'kg,${a['kg']}\n'
        'co2,${a['co2']}\n'
        'pending,${a['pending']}\n';
  }
}
