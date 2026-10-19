import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../admin/presentation/admin_shell.dart';
import '../../auth/providers/auth_providers.dart';
import '../../volunteer/presentation/moderate_claims_screen.dart';
import '../../volunteer/presentation/moderate_proofs_screen.dart';
import '../../volunteer/presentation/scan_screen.dart';

/// Рабочая вкладка для волонтёра и админа: подтверждение сдач, баллы, админ-панель.
class StaffWorkScreen extends ConsumerStatefulWidget {
  const StaffWorkScreen({super.key});

  @override
  ConsumerState<StaffWorkScreen> createState() => _StaffWorkScreenState();
}

class _StaffWorkScreenState extends ConsumerState<StaffWorkScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  void _ensureTabs(int length) {
    if (_tabs != null && _tabs!.length == length) return;
    _tabs?.dispose();
    _tabs = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(currentProfileProvider),
      ),
      data: (profile) {
        if (profile == null || !profile.isStaff) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                AppRu.staffAccessDenied,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final isAdmin = profile.isAdmin;
        final tabCount = isAdmin ? 4 : 3;
        _ensureTabs(tabCount);

        return Column(
          children: [
            Material(
              color: AppColors.primary,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAdmin ? AppRu.adminHub : AppRu.volunteerHub,
                            style: GoogleFonts.dmSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppRu.staffWorkSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabs,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabs: [
                        const Tab(
                          icon: Icon(Icons.qr_code_scanner_rounded, size: 20),
                          text: AppRu.scanQrShort,
                        ),
                        const Tab(
                          icon: Icon(Icons.fact_check_outlined, size: 20),
                          text: AppRu.moderateClaimsShort,
                        ),
                        const Tab(
                          icon: Icon(Icons.photo_camera_back_outlined, size: 20),
                          text: AppRu.moderateProofs,
                        ),
                        if (isAdmin)
                          const Tab(
                            icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                            text: AppRu.adminHubShort,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  const ScanScreen(embedded: true),
                  const ModerateClaimsScreen(embedded: true),
                  const ModerateProofsScreen(embedded: true),
                  if (isAdmin) const AdminPanelBody(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
