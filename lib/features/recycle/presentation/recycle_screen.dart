import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/recycle_repository.dart';
import '../models/recycling_submission.dart';

final _submissionsProvider =
    FutureProvider.autoDispose<List<RecyclingSubmission>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];
  return RecycleRepository().fetchRecentSubmissions(profile.id);
});

final _fractionsProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return {};
  return RecycleRepository().fetchFractionTotals(profile.id);
});

class RecycleScreen extends ConsumerWidget {
  const RecycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final submissionsAsync = ref.watch(_submissionsProvider);
    final fractionsAsync = ref.watch(_fractionsProvider);

    return profileAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (profile) {
        if (profile == null) {
          return const ErrorView(message: 'Profile not found');
        }

        final qrData = profile.qrToken ?? profile.id;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_submissionsProvider);
            ref.invalidate(_fractionsProvider);
            ref.invalidate(currentProfileProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const SectionHeader(
                title: 'Recycle Hub',
                subtitle: 'Scan your QR code at campus collection bins',
                serif: true,
              ),
              const SizedBox(height: 18),
              EcoCard(
                child: Column(
                  children: [
                    Text(
                      'Personal Eco-ID',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'MY ECO-ID',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          QrImageView(
                            data: qrData,
                            size: 180,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'SCAN FOR PROFILE',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hold QR code in front of the scanner light.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Your Recycled Items',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              fractionsAsync.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, _) => const Text('Failed to load stats'),
                data: (totals) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      _FractionCard(
                        icon: Icons.local_drink_outlined,
                        label: 'Plastic',
                        value: totals['plastic'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.description_outlined,
                        label: 'Paper',
                        value: totals['paper'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Metal',
                        value: totals['metal'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.battery_charging_full_outlined,
                        label: 'Batteries',
                        value: totals['hazardous'] ?? 0,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/recycle/upload'),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Upload Photo for Verification'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Recent Deposits',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              submissionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => Text(e.toString()),
                data: (items) {
                  if (items.isEmpty) {
                    return const EcoCard(
                      child: Text(
                        'No deposits yet. Upload a photo to get started.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DepositTile(item: item),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FractionCard extends StatelessWidget {
  const _FractionCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const Spacer(),
          Text(
            value < 1 && value > 0
                ? value.toStringAsFixed(1)
                : value.toStringAsFixed(0),
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({required this.item});

  final RecyclingSubmission item;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d, HH:mm').format(item.submittedAt.toLocal());
    final title =
        '${item.weightKg.toStringAsFixed(1)} kg ${item.categoryName ?? item.fraction ?? 'waste'}';
    final shortId = '#${item.id.substring(0, 4).toUpperCase()}';

    return EcoCard(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.isVerified ? AppColors.primary : AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$shortId • $time',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${item.pointsAwarded} pts',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isVerified
                      ? AppColors.verifiedBg
                      : AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isVerified ? 'Verified' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.isVerified
                        ? AppColors.verifiedFg
                        : AppColors.pendingFg,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}