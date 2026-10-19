import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/recycle_repository.dart';
import '../models/recycling_submission.dart';

final recycleRepositoryProvider = Provider<RecycleRepository>((ref) {
  return RecycleRepository();
});

final wasteCategoriesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(recycleRepositoryProvider).fetchCategories();
});

final submissionsProvider =
    FutureProvider.autoDispose<List<RecyclingSubmission>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ref.watch(recycleRepositoryProvider).fetchRecentSubmissions(profile.id);
});

final fractionsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return {};
  return ref.watch(recycleRepositoryProvider).fetchFractionTotals(profile.id);
});

final weeklyActivityProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return List.filled(7, 0);
  return ref.watch(recycleRepositoryProvider).fetchWeeklyCounts(profile.id);
});

final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return 0;
  return ref.watch(recycleRepositoryProvider).fetchActiveStreakDays(profile.id);
});

/// Инвалидирует данные после новой фото-заявки.
void invalidateRecycleData(WidgetRef ref) {
  ref.invalidate(submissionsProvider);
  ref.invalidate(fractionsProvider);
  ref.invalidate(weeklyActivityProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(currentProfileProvider);
}