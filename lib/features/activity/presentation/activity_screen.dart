import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/activity_repository.dart';
import '../models/activity_item.dart';

final _activityProvider =
    FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return ActivityRepository().fetchFeed(profile.id);
});

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  IconData _icon(ActivityKind kind) => switch (kind) {
        ActivityKind.deposit => Icons.recycling_rounded,
        ActivityKind.redeem => Icons.card_giftcard_rounded,
        ActivityKind.report => Icons.report_gmailerrorred_outlined,
      };

  Color _color(ActivityKind kind) => switch (kind) {
        ActivityKind.deposit => AppColors.primary,
        ActivityKind.redeem => AppColors.accentDeep,
        ActivityKind.report => AppColors.pendingFg,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_activityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppRu.activity)),
      body: AppPage(
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(_activityProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: AppRu.activityEmpty,
                  subtitle: AppRu.activityEmptyHint,
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(_activityProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final when = DateFormat('d MMM, HH:mm', 'ru')
                      .format(item.at.toLocal());
                  return EcoCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.mint,
                          child: Icon(_icon(item.kind), color: _color(item.kind)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                when,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.points != null)
                          Text(
                            item.points! > 0
                                ? '+${item.points}'
                                : '${item.points}',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              color: item.points! >= 0
                                  ? AppColors.primary
                                  : AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}