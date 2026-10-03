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
}