import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/recycle/presentation/recycle_screen.dart';
import '../../features/recycle/presentation/upload_claim_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../theme/app_colors.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/dashboard',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final loggedIn = authRepo.currentSession != null;
      final onAuth = state.matchedLocation == '/login';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
      backgroundColor: AppColors.background,
      body: Center(child: Text(state.error.toString())),
    ),
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this.ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}