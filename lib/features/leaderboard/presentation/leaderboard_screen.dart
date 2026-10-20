import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/leaderboard_repository.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardTabNotifier extends Notifier<LeaderboardTab> {
  @override
  LeaderboardTab build() => LeaderboardTab.students;

  void setTab(LeaderboardTab tab) => state = tab;
}

final _tabProvider = NotifierProvider<LeaderboardTabNotifier, LeaderboardTab>(
  LeaderboardTabNotifier.new,
);

class _MetricNotifier extends Notifier<LeaderboardMetric> {
  @override
  LeaderboardMetric build() => LeaderboardMetric.points;
  void set(LeaderboardMetric m) => state = m;
}

final _metricProvider =
    NotifierProvider<_MetricNotifier, LeaderboardMetric>(_MetricNotifier.new);

class _PeriodNotifier extends Notifier<LeaderboardPeriod> {
  @override
  LeaderboardPeriod build() => LeaderboardPeriod.all;
  void set(LeaderboardPeriod p) => state = p;
}

final _periodProvider =
    NotifierProvider<_PeriodNotifier, LeaderboardPeriod>(_PeriodNotifier.new);

final _leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>(
  (ref) {
    final tab = ref.watch(_tabProvider);
    final metric = ref.watch(_metricProvider);
    final period = ref.watch(_periodProvider);
    return LeaderboardRepository().fetch(
      tab,
      metric: metric,
      period: period,
    );
  },
);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final metric = ref.watch(_metricProvider);
    final period = ref.watch(_periodProvider);
    final boardAsync = ref.watch(_leaderboardProvider);
    final me = ref.watch(currentProfileProvider).asData?.value;

    return AppPage(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(_leaderboardProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const SectionHeader(
              title: AppRu.ecoLeaderboard,
              subtitle: AppRu.leaderboardSubtitle,
              serif: true,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final m in LeaderboardMetric.values)
                  ChoiceChip(
                    label: Text(switch (m) {
                      LeaderboardMetric.points => AppRu.metricPoints,
                      LeaderboardMetric.kg => AppRu.metricKg,
                      LeaderboardMetric.co2 => AppRu.metricCo2,
                      LeaderboardMetric.challenges => AppRu.metricChallenges,
                    }),
                    selected: metric == m,
                    onSelected: (_) =>
                        ref.read(_metricProvider.notifier).set(m),
                  ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final p in LeaderboardPeriod.values)
                  ChoiceChip(
                    label: Text(switch (p) {
                      LeaderboardPeriod.week => AppRu.periodWeek,
                      LeaderboardPeriod.month => AppRu.periodMonth,
                      LeaderboardPeriod.semester => AppRu.periodSemester,
                      LeaderboardPeriod.year => AppRu.periodYear,
                      LeaderboardPeriod.all => AppRu.periodAll,
                    }),
                    selected: period == p,
                    onSelected: (_) =>
                        ref.read(_periodProvider.notifier).set(p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFECEDE6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _TabChip(
                    label: AppRu.students,
                    selected: tab == LeaderboardTab.students,
                    onTap: () => ref
                        .read(_tabProvider.notifier)
                        .setTab(LeaderboardTab.students),
                  ),
                  _TabChip(
                    label: AppRu.groups,
                    selected: tab == LeaderboardTab.groups,
                    onTap: () => ref
                        .read(_tabProvider.notifier)
                        .setTab(LeaderboardTab.groups),
                  ),
                  _TabChip(
                    label: AppRu.faculties,
                    selected: tab == LeaderboardTab.faculties,
                    onTap: () => ref
                        .read(_tabProvider.notifier)
                        .setTab(LeaderboardTab.faculties),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            boardAsync.when(
              loading: () => const SizedBox(height: 240, child: LoadingView()),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(_leaderboardProvider),
              ),
              data: (rawEntries) {
                if (rawEntries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.leaderboard_rounded,
                    title: AppRu.leaderboardEmpty,
                  );
                }

                // Гарантируем уникальные места 1..n (на случай RANK() ties в старой БД).
                final entries = [
                  for (var i = 0; i < rawEntries.length; i++)
                    LeaderboardEntry(
                      id: rawEntries[i].id,
                      name: rawEntries[i].name,
                      greenPoints: rawEntries[i].greenPoints,
                      rank: i + 1,
                      subtitle: rawEntries[i].subtitle,
                      totalKg: rawEntries[i].totalKg,
                    ),
                ];

                final top = entries.take(3).toList();
                final rest = entries.skip(3).toList();
                final fmt = NumberFormat('#,###', 'ru');
                LeaderboardEntry? myEntry;
                for (final e in entries) {
                  if (me != null && e.id == me.id) {
                    myEntry = e;
                    break;
                  }
                }
                final shareEntry = myEntry;
                return Column(
                  children: [
                    if (top.isNotEmpty) _Podium(top: top, fmt: fmt),
                    if (shareEntry != null)
                      TextButton.icon(
                        onPressed: () async {
                          await saveRankSnapshot(
                            ref.read(sharedPreferencesProvider),
                            shareEntry.rank,
                          );
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Моё место в Eco-Tracker: #${shareEntry.rank} '
                                  '(${shareEntry.greenPoints} б.)',
                            ),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: Text('Поделиться: #${shareEntry.rank}'),
                      ),
                    const SizedBox(height: 16),
                    ...rest.map((entry) {
                      final isMe = me != null && entry.id == me.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: EcoCard(
                          color: isMe ? const Color(0xFFE8F8D8) : Colors.white,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${entry.rank}',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.mint,
                                child: Text(
                                  entry.name.isNotEmpty
                                      ? entry.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isMe
                                      ? '${entry.name} (${AppRu.you})'
                                      : entry.name,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${fmt.format(entry.greenPoints)} ${AppRu.pointsShort}',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.fmt});

  final List<LeaderboardEntry> top;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    // Места по порядку списка: 1-й, 2-й, 3-й — без привязки к SQL RANK().
    final first = top.isNotEmpty ? top[0] : null;
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              entry: second,
              place: 2,
              height: 100,
              color: AppColors.mint,
              numberColor: AppColors.primary,
              fmt: fmt,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: first,
              place: 1,
              height: 130,
              color: AppColors.primary,
              numberColor: Colors.white,
              fmt: fmt,
              crown: true,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: third,
              place: 3,
              height: 80,
              color: AppColors.mint,
              numberColor: AppColors.primary,
              fmt: fmt,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.place,
    required this.height,
    required this.color,
    required this.numberColor,
    required this.fmt,
    this.crown = false,
  });

  final LeaderboardEntry? entry;
  final int place;
  final double height;
  final Color color;
  final Color numberColor;
  final NumberFormat fmt;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final short = entry!.name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crown)
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.accent,
              size: 22,
            )
          else
            const SizedBox(height: 22),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.mint,
            child: Text(
              short.isNotEmpty ? short[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          Text(
            '${fmt.format(entry!.greenPoints)} ${AppRu.pointsShort}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              '$place',
              style: GoogleFonts.dmSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: numberColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
