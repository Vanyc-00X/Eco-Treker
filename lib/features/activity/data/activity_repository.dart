import '../../../core/supabase/supabase_init.dart';
import '../models/activity_item.dart';

class ActivityRepository {
  Future<List<ActivityItem>> fetchFeed(String userId) async {
    final items = <ActivityItem>[];

    try {
      final deposits = await supabase
          .from('recycling_submissions')
          .select('id, weight_kg, status, points_awarded, submitted_at, waste_categories(name_ru)')
          .eq('student_id', userId)
          .order('submitted_at', ascending: false)
          .limit(20);
      for (final row in deposits) {
        final cat = row['waste_categories'];
        final name = cat is Map ? cat['name_ru'] as String? : null;
        final status = row['status'] as String? ?? 'pending';
        items.add(
          ActivityItem(
            id: 'd-${row['id']}',
            kind: ActivityKind.deposit,
            title: 'Сдача: ${name ?? 'отходы'}',
            subtitle:
                '${(row['weight_kg'] as num?)?.toDouble().toStringAsFixed(1) ?? '0'} кг · ${status == 'verified' ? 'проверено' : 'на проверке'}',
            at: DateTime.tryParse(row['submitted_at'] as String? ?? '') ??
                DateTime.now(),
            points: (row['points_awarded'] as num?)?.toInt(),
          ),
        );
      }
    } catch (_) {}

    try {
      final redeems = await supabase
          .from('redeem_requests')
          .select()
          .eq('student_id', userId)
          .order('created_at', ascending: false)
          .limit(15);
      for (final row in redeems) {
        items.add(
          ActivityItem(
            id: 'r-${row['id']}',
            kind: ActivityKind.redeem,
            title: 'Обмен: ${row['reward_title'] ?? 'награда'}',
            subtitle: '−${row['points_cost'] ?? 0} б. · ${row['status']}',
            at: DateTime.tryParse(row['created_at'] as String? ?? '') ??
                DateTime.now(),
            points: -((row['points_cost'] as num?)?.toInt() ?? 0),
          ),
        );
      }
    } catch (_) {}

    try {
      final reports = await supabase
          .from('bin_reports')
          .select('id, status, created_at, note')
          .eq('reporter_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      for (final row in reports) {
        items.add(
          ActivityItem(
            id: 'b-${row['id']}',
            kind: ActivityKind.report,
            title: 'Жалоба на контейнер',
            subtitle: (row['note'] as String?)?.isNotEmpty == true
                ? row['note'] as String
                : 'Статус: ${row['status']}',
            at: DateTime.tryParse(row['created_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }
    } catch (_) {}

    items.sort((a, b) => b.at.compareTo(a.at));
    return items.take(40).toList();
  }
}