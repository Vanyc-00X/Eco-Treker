import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
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

final _tabProvider =
    NotifierProvider<LeaderboardTabNotifier, LeaderboardTab>(
  LeaderboardTabNotifier.new,
);

final _leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  final tab = ref.watch(_tabProvider);
  return LeaderboardRepository().fetch(tab);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final boardAsync = ref.watch(_leaderboardProvider);
    final me = ref.watch(currentProfileProvider).asData?.value;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_leaderboardProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const SectionHeader(
            title: 'Eco Leaderboard',
            subtitle: 'See how you stack up against the campus',
            serif: true,
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
                  label: 'Students',
                  selected: tab == LeaderboardTab.students,
                  onTap: () => ref
                      .read(_tabProvider.notifier)
                      .setTab(LeaderboardTab.students),
                ),
                _TabChip(
                  label: 'Groups',
                  selected: tab == LeaderboardTab.groups,
                  onTap: () => ref
                      .read(_tabProvider.notifier)
                      .setTab(LeaderboardTab.groups),
                ),
                _TabChip(
                  label: 'Faculties',
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
            loading: () => const SizedBox(
              height: 240,
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(_leaderboardProvider),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const EcoCard(
                  child: Text('Leaderboard is empty for now.'),
                );
              }

              final top = entries.take(3).toList();
              final rest = entries.skip(3).toList();
              final fmt = NumberFormat('#,###');

              return Column(
                children: [
                  if (top.isNotEmpty) _Podium(top: top, fmt: fmt),
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
                                isMe ? '${entry.name} (You)' : entry.name,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${fmt.format(entry.greenPoints)} pts',
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
    LeaderboardEntry? first;
    LeaderboardEntry? second;
    LeaderboardEntry? third;
    for (final e in top) {
      if (e.rank == 1) first = e;
      if (e.rank == 2) second = e;
      if (e.rank == 3) third = e;
    }
    first ??= top.isNotEmpty ? top[0] : null;
    second ??= top.length > 1 ? top[1] : null;
    third ??= top.length > 2 ? top[2] : null;

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              entry: second,
              height: 110,
              color: AppColors.mint,
              numberColor: AppColors.primary,
              fmt: fmt,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: first,
              height: 140,
              color: AppColors.primary,
              numberColor: Colors.white,
              fmt: fmt,
              crown: true,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: third,
              height: 90,
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
    required this.height,
    required this.color,
    required this.numberColor,
    required this.fmt,
    this.crown = false,
  });

  final LeaderboardEntry? entry;
  final double height;
  final Color color;
  final Color numberColor;
  final NumberFormat fmt;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final short = entry!.name.split(' ').first;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (crown)
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.accent, size: 22),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.mint,
          child: Text(
            short.isNotEmpty ? short[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          short,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
        ),
        Text(
          '${fmt.format(entry!.greenPoints)} pts',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(
            '${entry!.rank}',
            style: GoogleFonts.dmSans(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: numberColor,
            ),
          ),
        ),
      ],
    );
  }
}