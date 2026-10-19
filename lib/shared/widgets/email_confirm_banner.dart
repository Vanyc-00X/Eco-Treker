import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_ru.dart';
import '../../core/prefs/app_prefs.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_providers.dart';

const _kEmailBannerDismissedAt = 'email_confirm_banner_dismissed_at';

/// Каждые 10 минут показывает «Подтвердите почту!», если email не подтверждён.
/// Можно закрыть — снова появится через 10 минут.
class EmailConfirmBannerHost extends ConsumerStatefulWidget {
  const EmailConfirmBannerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EmailConfirmBannerHost> createState() =>
      _EmailConfirmBannerHostState();
}

class _EmailConfirmBannerHostState
    extends ConsumerState<EmailConfirmBannerHost> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _evaluate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _evaluate() {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser;
    if (user == null || repo.isEmailConfirmed) {
      if (_visible) setState(() => _visible = false);
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_kEmailBannerDismissedAt);
    final dismissedAt = raw == null ? null : DateTime.tryParse(raw);
    final canShow = dismissedAt == null ||
        DateTime.now().difference(dismissedAt) >= const Duration(minutes: 10);

    if (canShow && !_visible) {
      setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _kEmailBannerDismissedAt,
      DateTime.now().toIso8601String(),
    );
    setState(() => _visible = false);
  }

  Future<void> _resend() async {
    final email = ref.read(authRepositoryProvider).currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(authRepositoryProvider).resendSignupEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppRu.confirmEmailResent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppRu.confirmEmailResendFailed}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, _) => _evaluate());

    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFFFF3CD),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_unread_outlined,
                        color: Color(0xFF856404)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            AppRu.confirmEmailBanner,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF856404),
                            ),
                          ),
                          TextButton(
                            onPressed: _resend,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text(AppRu.resendConfirmEmail),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close, color: Color(0xFF856404)),
                      tooltip: AppRu.cancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
