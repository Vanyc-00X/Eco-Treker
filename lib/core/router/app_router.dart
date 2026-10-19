import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/activity_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/recycle/presentation/recycle_screen.dart';
import '../../features/recycle/presentation/upload_claim_screen.dart';
import '../../features/settings/presentation/legal_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/volunteer/presentation/moderate_claims_screen.dart';
import '../../features/volunteer/presentation/moderate_proofs_screen.dart';
import '../../features/volunteer/presentation/scan_screen.dart';
import '../../features/volunteer/presentation/volunteer_shell.dart';
import '../../shared/widgets/main_shell.dart';
import '../l10n/app_ru.dart';
import '../prefs/app_prefs.dart';
import '../theme/app_colors.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/dashboard',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final loggedIn = authRepo.currentSession != null;
      final onboardingDone = ref.read(onboardingDoneProvider);
      final loc = state.matchedLocation;
      final onAuth = loc == '/login';
      final onOnboarding = loc == '/onboarding';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        return onboardingDone ? '/dashboard' : '/onboarding';
      }
      if (loggedIn && !onboardingDone && !onOnboarding) return '/onboarding';
      if (loggedIn && onboardingDone && onOnboarding) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/legal/tos',
        builder: (context, state) =>
            const LegalScreen(doc: LegalDoc.tos),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) =>
            const LegalScreen(doc: LegalDoc.privacy),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
      ShellRoute(
        builder: (context, state, child) => VolunteerShell(child: child),
        routes: [
          GoRoute(
            path: '/volunteer',
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: '/volunteer/moderate',
            builder: (context, state) => const ModerateClaimsScreen(),
          ),
          GoRoute(
            path: '/volunteer/proofs',
            builder: (context, state) => const ModerateProofsScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recycle',
                builder: (context, state) => const RecycleScreen(),
                routes: [
                  GoRoute(
                    path: 'upload',
                    builder: (context, state) => const UploadClaimScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/challenges',
                builder: (context, state) => const ChallengesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              const Text(AppRu.pageNotFound, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text(AppRu.goHome),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(onboardingDoneProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}
