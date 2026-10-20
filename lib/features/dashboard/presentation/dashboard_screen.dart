import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/tips/eco_tips.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../recycle/providers/recycle_providers.dart';
import '../../rewards/data/rewards_repository.dart';
import '../../rewards/models/redeem_request.dart';
import '../../rewards/models/reward_item.dart';

/// Цель серии (дней) для индикатора прогресса.
const _streakGoalDays = 7;

/// Условный коэффициент: кг CO₂, которые поглощает одно дерево за год.
const _co2KgPerTreeYear = 21;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _openRedeem(
    BuildContext context,
    WidgetRef ref,
    String userId,
    int balance,
  ) async {
    final reward = await showModalBottomSheet<RewardItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RedeemSheet(userId: userId, balance: balance),
    );

    if (reward == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(reward.title),
        content: Text(
          'Списать ${reward.pointsCost} ${AppRu.pointsShort} с баланса?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppRu.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppRu.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await RewardsRepository().redeem(reward);
      ref.invalidate(currentProfileProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppRu.redeemSuccess)));
    } catch (e) {
      if (!context.mounted) return;
      final raw = e.toString();
      final msg = raw.contains('Недостаточно') || raw.contains('enough')
          ? AppRu.redeemNotEnough
          : '${AppRu.redeemFailed}: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final weeklyAsync = ref.watch(weeklyActivityProvider);
    final streakAsync = ref.watch(streakProvider);

    return AppPage(
      child: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return ErrorView(
              message: AppRu.profileNotFound,
              onRetry: () => ref.invalidate(currentProfileProvider),
            );
          }

          final onSurface = Theme.of(context).colorScheme.onSurface;
          final pointsFmt = NumberFormat(
            '#,###',
            'ru',
          ).format(profile.greenPoints);
          final streakDays = streakAsync.asData?.value ?? 0;
          final streakProgress = (streakDays / _streakGoalDays)
              .clamp(0, 1)
              .toDouble();
          final trees = profile.co2SavedKg / _co2KgPerTreeYear;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(currentProfileProvider);
              ref.invalidate(weeklyActivityProvider);
              ref.invalidate(streakProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: AppRu.editProfileHint,
                      child: InkWell(
                        onTap: () => context.push('/profile/edit'),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.mint,
                          backgroundImage: profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? Text(
                                  profile.displayName.isNotEmpty
                                      ? profile.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${profile.ecoLevelLabel} ур.${profile.ecoLevelNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: AppRu.activity,
                      onPressed: () => context.push('/activity'),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: AppRu.settings,
                      onPressed: () => context.push('/settings'),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                EcoCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppRu.greenPointsBalance,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                letterSpacing: 0.6,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.eco,
                                  color: AppColors.accent,
                                  size: 28,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  pointsFmt,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _openRedeem(
                          context,
                          ref,
                          profile.id,
                          profile.greenPoints,
                        ),
                        child: const Text(AppRu.redeem),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatMini(
                        icon: Icons.cloud_outlined,
                        value: '${profile.co2SavedKg.toStringAsFixed(1)} кг',
                        label: AppRu.co2Saved,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMini(
                        icon: Icons.recycling_rounded,
                        value: '${profile.totalKg.toStringAsFixed(1)} кг',
                        label: AppRu.recycled,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMini(
                        icon: Icons.local_fire_department_rounded,
                        value: '$streakDays ${AppRu.daysUnit}',
                        label: AppRu.activeStreak,
                        iconColor: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                EcoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppRu.streakGoal,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${streakDays.clamp(0, _streakGoalDays)}/$_streakGoalDays',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: streakProgress,
                          minHeight: 8,
                          backgroundColor: AppColors.progressTrack,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                EcoCard(
                  color: AppColors.mint,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.park_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppRu.impactTitle,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppRu.treesEquiv} ${trees.toStringAsFixed(1)}',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              AppRu.impactBody,
                              style: const TextStyle(
                                color: AppColors.primarySoft,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                EcoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            AppRu.weeklyActivity,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppRu.kgRecycled,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: weeklyAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, _) =>
                              const Center(child: Text(AppRu.noData)),
                          data: (values) => _WeeklyBars(values: values),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppRu.tipOfDay,
                              style: GoogleFonts.dmSans(
                                color: AppColors.primarySoft,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              EcoTips.forDay(),
                              style: GoogleFonts.dmSans(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RedeemSheet extends StatelessWidget {
  const _RedeemSheet({required this.userId, required this.balance});

  final String userId;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppRu.redeemTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppRu.redeemSubtitle,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  unselectedLabelColor: AppColors.muted,
                  tabs: [
                    Tab(text: AppRu.rewardsTab),
                    Tab(text: AppRu.redeemHistory),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _RewardsList(balance: balance),
                      _RedeemHistoryList(userId: userId),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppRu.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardsList extends StatelessWidget {
  const _RewardsList({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: kCampusRewards.map((item) {
        final canAfford = balance >= item.pointsCost;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Opacity(
            opacity: canAfford ? 1 : 0.55,
            child: EcoCard(
              onTap: canAfford ? () => Navigator.pop(context, item) : null,
              child: Row(
                children: [
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
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.pointsCost} ${AppRu.pointsShort}',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w800,
                      color: canAfford ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RedeemHistoryList extends StatefulWidget {
  const _RedeemHistoryList({required this.userId});

  final String userId;

  @override
  State<_RedeemHistoryList> createState() => _RedeemHistoryListState();
}

class _RedeemHistoryListState extends State<_RedeemHistoryList> {
  late Future<List<RedeemRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = RewardsRepository().fetchHistory(widget.userId);
  }

  void _reload() {
    setState(() {
      _future = RewardsRepository().fetchHistory(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RedeemRequest>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }
        final items = snapshot.data ?? const <RedeemRequest>[];
        if (items.isEmpty) {
          return ListView(
            children: const [
              EmptyState(
                icon: Icons.card_giftcard_rounded,
                title: AppRu.redeemHistoryEmpty,
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            final when = DateFormat(
              'd MMM, HH:mm',
              'ru',
            ).format(item.createdAt.toLocal());
            return EcoCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.rewardTitle,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$when • ${item.statusRu}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-${item.pointsCost} ${AppRu.pointsShort}',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    final today = DateTime.now().weekday - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final v = i < values.length ? values[i] : 0;
        final h = max <= 0 ? 12.0 : 20 + (v / max) * 90;
        final active = i == today;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: h,
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: TextStyle(
                    color: active ? AppColors.primary : AppColors.muted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
