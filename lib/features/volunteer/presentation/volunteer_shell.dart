import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/theme/app_colors.dart';

class VolunteerShell extends StatelessWidget {
  const VolunteerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    var index = 0;
    if (loc.contains('moderate')) index = 1;
    if (loc.contains('proofs')) index = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/volunteer');
            case 1:
              context.go('/volunteer/moderate');
            case 2:
              context.go('/volunteer/proofs');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: AppRu.scanQr,
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: AppRu.moderateClaims,
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_back_outlined),
            label: 'Пруфы',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/dashboard'),
        backgroundColor: AppColors.accentDeep,
        icon: const Icon(Icons.home_outlined),
        label: const Text(AppRu.goHome),
      ),
    );
  }
}
