import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Обёртка экрана: SafeArea + опциональный градиентный фон.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.padding,
    this.gradient = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = SafeArea(
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (!gradient) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF132019), AppColors.backgroundDark]
              : const [AppColors.gradientTop, AppColors.gradientBottom],
        ),
      ),
      child: content,
    );
  }
}