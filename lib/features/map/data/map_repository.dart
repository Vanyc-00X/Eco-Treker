import '../../../core/supabase/supabase_init.dart';
import '../models/collection_point.dart';

class MapRepository {
  Future<List<CollectionPoint>> fetchPoints() async {
    final rows = await supabase
        .from('collection_points')
        .select()
        .eq('is_active', true)
        .order('name');
    return rows.map((e) => CollectionPoint.fromJson(e)).toList();
  }

  Future<void> reportFullBin({
    required String reporterId,
    required String collectionPointId,
    String? note,
  }) async {
    await supabase.from('bin_reports').insert({
      'reporter_id': reporterId,
      'collection_point_id': collectionPointId,
      'note': note,
      'status': 'open',
    });
  }

  Future<Set<String>> fetchFavoriteIds(String userId) async {
    final rows = await supabase
        .from('favorites_points')
        .select('collection_point_id')
        .eq('user_id', userId);
    return rows
        .map((e) => e['collection_point_id'] as String)
        .toSet();
  }

  Future<void> toggleFavorite({
    required String userId,
    required String pointId,
    required bool favorite,
  }) async {
    if (favorite) {
      await supabase.from('favorites_points').upsert({
        'user_id': userId,
        'collection_point_id': pointId,
      });
    } else {
      await supabase
          .from('favorites_points')
          .delete()
          .eq('user_id', userId)
          .eq('collection_point_id', pointId);
    }
  }
}
