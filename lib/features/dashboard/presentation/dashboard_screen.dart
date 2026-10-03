import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../recycle/data/recycle_repository.dart';

final _weeklyProvider = FutureProvider.autoDispose<List<double>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return List.filled(7, 0);
  return RecycleRepository().fetchWeeklyCounts(profile.id);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final weeklyAsync = ref.watch(_weeklyProvider);

    return profileAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(currentProfileProvider),
      ),
      data: (profile) {
        if (profile == null) {
          return const ErrorView(message: 'Profile not found');
        }

        final pointsFmt = NumberFormat('#,###').format(profile.greenPoints);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(currentProfileProvider);
            ref.invalidate(_weeklyProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.mint,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(
                            profile.fullName.isNotEmpty
                                ? profile.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
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
                            '${profile.ecoLevelLabel} Lv.${profile.ecoLevelNumber}',
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
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
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
                            'GREEN POINTS BALANCE',
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
                              const Icon(Icons.eco, color: AppColors.accent, size: 28),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Redeem coming soon in next version'),
                          ),
                        );
                      },
                      child: const Text('Redeem'),
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
                      value: '${profile.co2SavedKg.toStringAsFixed(1)} kg',
                      label: 'CO2 Saved',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatMini(
                      icon: Icons.recycling_rounded,
                      value: '${profile.totalKg.toStringAsFixed(1)} kg',
                      label: 'Recycled',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _StatMini(
                      icon: Icons.local_fire_department_rounded,
                      value: '8 days',
                      label: 'Active Streak',
                      iconColor: Color(0xFFE53935),
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
                        Text(
                          'Weekly Activity',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Items Recycled',
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
                        error: (_, _) => const Center(child: Text('No data')),
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
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tip: Rinse bottles before deposit to earn an extra 5 bonus points!',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              color: Colors.black87,
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
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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