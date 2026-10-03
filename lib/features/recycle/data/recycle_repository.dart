import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../models/recycling_submission.dart';
import '../models/waste_category.dart';

class RecycleRepository {
  Future<List<WasteCategory>> fetchCategories() async {
    final rows = await supabase.from('waste_categories').select().order('name_ru');
    return rows.map((e) => WasteCategory.fromJson(e)).toList();
  }

  Future<List<RecyclingSubmission>> fetchRecentSubmissions(String userId) async {
    final rows = await supabase
        .from('recycling_submissions')
        .select('*, waste_categories(fraction, name_ru)')
        .eq('student_id', userId)
        .order('submitted_at', ascending: false)
        .limit(20);
    return rows.map((e) => RecyclingSubmission.fromJson(e)).toList();
  }

  Future<Map<String, double>> fetchFractionTotals(String userId) async {
    final rows = await supabase
        .from('recycling_submissions')
        .select('weight_kg, status, waste_categories(fraction)')
        .eq('student_id', userId)
        .eq('status', 'verified');

    final totals = <String, double>{
      'plastic': 0,
      'paper': 0,
      'metal': 0,
      'glass': 0,
      'hazardous': 0,
    };

    for (final row in rows) {
      final category = row['waste_categories'];
      final fraction = category is Map ? category['fraction'] as String? : null;
      final weight = (row['weight_kg'] as num?)?.toDouble() ?? 0;
      if (fraction != null) {
        totals[fraction] = (totals[fraction] ?? 0) + weight;
      }
    }
    return totals;
  }

  Future<List<double>> fetchWeeklyCounts(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final rows = await supabase
        .from('recycling_submissions')
        .select('submitted_at, weight_kg')
        .eq('student_id', userId)
        .gte('submitted_at', start.toUtc().toIso8601String());

    final counts = List<double>.filled(7, 0);
    for (final row in rows) {
      final dt = DateTime.tryParse(row['submitted_at'] as String? ?? '');
      if (dt == null) continue;
      final local = dt.toLocal();
      final index = local.weekday - 1;
      if (index >= 0 && index < 7) {
        counts[index] += (row['weight_kg'] as num?)?.toDouble() ?? 1;
      }
    }
    return counts;
  }

  Future<RecyclingSubmission> createPhotoClaim({
    required String studentId,
    required String categoryId,
    required double weightKg,
    required Uint8List imageBytes,
    required String fileExt,
    String? note,
    String? collectionPointId,
  }) async {
    final path =
        '$studentId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await supabase.storage.from('submissions').uploadBinary(
          path,
          imageBytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExt',
            upsert: true,
          ),
        );

    final photoUrl = supabase.storage.from('submissions').getPublicUrl(path);

    final row = await supabase
        .from('recycling_submissions')
        .insert({
          'student_id': studentId,
          'category_id': categoryId,
          'collection_point_id': collectionPointId,
          'method': 'photo_claim',
          'status': 'pending',
          'weight_kg': weightKg,
          'photo_url': photoUrl,
          'note': note,
        })
        .select('*, waste_categories(fraction, name_ru)')
        .single();

    return RecyclingSubmission.fromJson(row);
  }
}