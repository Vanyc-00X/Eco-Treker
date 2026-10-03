import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                _NavItem(
                  index: 0,
                  current: navigationShell.currentIndex,
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 1,
                  current: navigationShell.currentIndex,
                  icon: Icons.delete_outline_rounded,
                  label: 'Recycle',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 2,
                  current: navigationShell.currentIndex,
                  icon: Icons.emoji_events_outlined,
                  label: 'Challenges',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 3,
                  current: navigationShell.currentIndex,
                  icon: Icons.radar_rounded,
                  label: 'Leaderboard',
                  onTap: _onTap,
                ),
                _NavItem(
                  index: 4,
                  current: navigationShell.currentIndex,
                  icon: Icons.location_on_outlined,
                  label: 'Map',
                  onTap: _onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.current,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int current;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.mint : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}