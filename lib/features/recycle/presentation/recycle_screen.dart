import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/qr_token.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/recycling_submission.dart';
import '../providers/recycle_providers.dart';

class RecycleScreen extends ConsumerStatefulWidget {
  const RecycleScreen({super.key});

  @override
  ConsumerState<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends ConsumerState<RecycleScreen> {
  bool _ensuringQr = false;
  Timer? _qrTimer;
  String _statusFilter = 'all';
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureQr());
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          _secondsLeft = 30;
        }
      });
      if (_secondsLeft == 30) {
        try {
          await ref.read(authRepositoryProvider).rotateQrToken();
          ref.invalidate(currentProfileProvider);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    super.dispose();
  }

  Future<void> _ensureQr() async {
    final profile = ref.read(currentProfileProvider).asData?.value;
    if (profile == null ||
        (profile.qrToken != null && profile.qrToken!.isNotEmpty)) {
      return;
    }
    if (_ensuringQr) return;
    setState(() => _ensuringQr = true);
    try {
      await ref.read(authRepositoryProvider).ensureQrToken();
      ref.invalidate(currentProfileProvider);
    } catch (_) {
      // Кнопка «Обновить QR» остаётся доступной.
    } finally {
      if (mounted) setState(() => _ensuringQr = false);
    }
  }

  Future<void> _rotateQr() async {
    try {
      await ref.read(authRepositoryProvider).rotateQrToken();
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppRu.qrRotated)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _copyEcoId(String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppRu.copied)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final submissionsAsync = ref.watch(submissionsProvider);
    final fractionsAsync = ref.watch(fractionsProvider);

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

          final token = profile.qrToken;
          final hasQr = token != null && token.isNotEmpty;
          final qrData = hasQr ? buildEcoQrPayload(token) : null;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await _ensureQr();
              invalidateRecycleData(ref);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth =
                    constraints.maxWidth > 720 ? 640.0 : constraints.maxWidth;
                return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                const SectionHeader(
                  title: AppRu.recycleHub,
                  subtitle: AppRu.recycleHubSubtitle,
                  serif: true,
                ),
                const SizedBox(height: 18),
                EcoCard(
                  child: Column(
                    children: [
                      Text(
                        AppRu.personalEcoId,
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
                              AppRu.myEcoId,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 1,
                              ),
                            ),
                            if (qrData != null)
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
                              )
                            else
                              SizedBox(
                                height: 180,
                                width: 180,
                                child: Center(
                                  child: _ensuringQr
                                      ? const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          AppRu.qrMissing,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                            Text(
                              AppRu.scanForProfile,
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
                      Text(
                        '${AppRu.holdQr} Обновление через $_secondsLeft с. '
                        'Увеличьте яркость экрана для сканера.',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: _rotateQr,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(AppRu.rotateQr),
                          ),
                          TextButton.icon(
                            onPressed: qrData == null
                                ? null
                                : () => _copyEcoId(qrData),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text(AppRu.copyEcoId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.sensors_outlined),
                          title: Text(AppRu.iotStub),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppRu.yourRecycled,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                fractionsAsync.when(
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, _) => const Text(AppRu.failedStats),
                  data: (totals) {
                    final cards = [
                      _FractionCard(
                        icon: Icons.local_drink_outlined,
                        label: AppRu.plastic,
                        value: totals['plastic'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.description_outlined,
                        label: AppRu.paper,
                        value: totals['paper'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.inventory_2_outlined,
                        label: AppRu.metal,
                        value: totals['metal'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.liquor_outlined,
                        label: AppRu.glass,
                        value: totals['glass'] ?? 0,
                      ),
                      _FractionCard(
                        icon: Icons.battery_charging_full_outlined,
                        label: AppRu.batteries,
                        value: totals['hazardous'] ?? 0,
                      ),
                    ];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final crossAxisCount = w >= 900
                            ? 5
                            : w >= 560
                                ? 3
                                : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: crossAxisCount >= 5 ? 1.05 : 1.25,
                          children: cards,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/recycle/upload'),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text(AppRu.uploadPhoto),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppRu.recentDeposits,
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final csv = await ref
                            .read(recycleRepositoryProvider)
                            .exportCsv();
                        await SharePlus.instance.share(ShareParams(text: csv));
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text(AppRu.exportCsv),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final f in [
                      ('all', AppRu.filterAll),
                      ('verified', AppRu.verified),
                      ('pending', AppRu.pending),
                      ('rejected', AppRu.rejected),
                    ])
                      ChoiceChip(
                        label: Text(f.$2),
                        selected: _statusFilter == f.$1,
                        onSelected: (_) =>
                            setState(() => _statusFilter = f.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                submissionsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Text(e.toString()),
                  data: (items) {
                    final filtered = _statusFilter == 'all'
                        ? items
                        : items
                            .where((e) => e.status == _statusFilter)
                            .toList();
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.recycling_rounded,
                        title: AppRu.noDeposits,
                        actionLabel: AppRu.uploadPhoto,
                        onAction: () => context.push('/recycle/upload'),
                      );
                    }
                    return Column(
                      children: [
                        ...filtered.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DepositTile(
                              item: item,
                              onDispute: () async {
                                await ref
                                    .read(recycleRepositoryProvider)
                                    .createDispute(
                                      submissionId: item.id,
                                      reason: 'Оспаривание начисления',
                                    );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(AppRu.disputePoints),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                      ],
                    ),
                  ),
                ),
              ],
            );
              },
            ),
          );
        },
      ),
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const Spacer(),
          Text(
            value < 1 && value > 0
                ? value.toStringAsFixed(1)
                : value.toStringAsFixed(0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({required this.item, this.onDispute});

  final RecyclingSubmission item;
  final VoidCallback? onDispute;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat(
      'd MMM, HH:mm',
      'ru',
    ).format(item.submittedAt.toLocal());
    final title =
        '${item.weightKg.toStringAsFixed(1)} кг ${item.categoryName ?? item.fraction ?? 'отходы'}';
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
                if (onDispute != null)
                  TextButton(
                    onPressed: onDispute,
                    child: const Text(AppRu.disputePoints),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${item.pointsAwarded} ${AppRu.pointsShort}',
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
                      : item.status == 'rejected'
                          ? const Color(0xFFFFEBEE)
                          : AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isVerified
                      ? AppRu.verified
                      : item.status == 'rejected'
                          ? AppRu.rejected
                          : AppRu.pending,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.isVerified
                        ? AppColors.verifiedFg
                        : item.status == 'rejected'
                            ? AppColors.danger
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
