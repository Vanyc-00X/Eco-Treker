import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/prefs/app_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../auth/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref, {
    bool everywhere = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(everywhere ? AppRu.logoutEverywhere : AppRu.logout),
        content: const Text(AppRu.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppRu.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppRu.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await clearLocalCache(ref.read(sharedPreferencesProvider));
      await ref.read(authRepositoryProvider).signOut(everywhere: everywhere);
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppRu.deleteAccount),
        content: const Text(AppRu.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppRu.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppRu.deleteAccount),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authRepositoryProvider).softDeleteAccount();
      await clearLocalCache(ref.read(sharedPreferencesProvider));
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeCodeProvider);
    final notif = ref.watch(notificationPrefsProvider);
    final accent = ref.watch(accentColorProvider);
    final profile = ref.watch(currentProfileProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text(AppRu.settings)),
      body: AppPage(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ListView(
          children: [
            Text(
              AppRu.theme,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            EcoCard(
              child: Column(
                children: [
                  _ThemeTile(
                    label: AppRu.themeSystem,
                    selected: mode == ThemeMode.system,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.system),
                  ),
                  const Divider(height: 1),
                  _ThemeTile(
                    label: AppRu.themeLight,
                    selected: mode == ThemeMode.light,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.light),
                  ),
                  const Divider(height: 1),
                  _ThemeTile(
                    label: AppRu.themeDark,
                    selected: mode == ThemeMode.dark,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(ThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppRu.language,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            EcoCard(
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('RU'),
                    selected: locale == 'ru',
                    onSelected: (_) =>
                        ref.read(localeCodeProvider.notifier).setLocale('ru'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('EN'),
                    selected: locale == 'en',
                    onSelected: (_) =>
                        ref.read(localeCodeProvider.notifier).setLocale('en'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppRu.accentColor,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            EcoCard(
              child: Wrap(
                spacing: 8,
                children: [
                  for (final c in ['green', 'teal', 'forest'])
                    ChoiceChip(
                      label: Text(c),
                      selected: accent == c,
                      onSelected: (_) async {
                        await ref
                            .read(accentColorProvider.notifier)
                            .setAccent(c);
                        if (profile != null) {
                          await ref.read(authRepositoryProvider).updateProfile(
                                fullName: profile.fullName,
                                accentColor: c,
                              );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppRu.notifications,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            EcoCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Новые челленджи'),
                    value: notif.challenges,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .update(notif.copyWith(challenges: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Напоминания о сдаче'),
                    value: notif.reminders,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .update(notif.copyWith(reminders: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Изменения в рейтинге'),
                    value: notif.ranking,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .update(notif.copyWith(ranking: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Системные'),
                    value: notif.system,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .update(notif.copyWith(system: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Акции'),
                    value: notif.promos,
                    onChanged: (v) => ref
                        .read(notificationPrefsProvider.notifier)
                        .update(notif.copyWith(promos: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppRu.privacy,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            EcoCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppRu.showInLeaderboard),
                    value: profile?.showInLeaderboard ?? true,
                    onChanged: profile == null
                        ? null
                        : (v) async {
                            await ref.read(authRepositoryProvider).updateProfile(
                                  fullName: profile.fullName,
                                  showInLeaderboard: v,
                                );
                            ref.invalidate(currentProfileProvider);
                          },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppRu.profilePublic),
                    value: profile?.profileVisibility == 'public',
                    onChanged: profile == null
                        ? null
                        : (v) async {
                            await ref.read(authRepositoryProvider).updateProfile(
                                  fullName: profile.fullName,
                                  profileVisibility: v ? 'public' : 'private',
                                );
                            ref.invalidate(currentProfileProvider);
                          },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppRu.enable2fa),
                    value: profile?.mfaEnabled ?? false,
                    onChanged: profile == null
                        ? null
                        : (v) async {
                            await ref.read(authRepositoryProvider).updateProfile(
                                  fullName: profile.fullName,
                                  mfaEnabled: v,
                                );
                            ref.invalidate(currentProfileProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    v
                                        ? '2FA включена (флаг профиля; MFA TOTP — при настройке Supabase)'
                                        : '2FA выключена',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            EcoCard(
              onTap: () => context.push('/profile/edit'),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_outline_rounded),
                title: Text(AppRu.editProfile),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            EcoCard(
              onTap: () => context.push('/activity'),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.notifications_none_rounded),
                title: Text(AppRu.activity),
                subtitle: Text(AppRu.activitySubtitle),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            if (profile?.isVolunteer == true || profile?.isAdmin == true) ...[
              const SizedBox(height: 10),
              EcoCard(
                onTap: () => context.go('/volunteer'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.qr_code_scanner_rounded),
                  title: Text(AppRu.volunteerHub),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
            if (profile?.isAdmin == true) ...[
              const SizedBox(height: 10),
              EcoCard(
                onTap: () => context.go('/admin'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text(AppRu.adminHub),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
            const SizedBox(height: 10),
            EcoCard(
              onTap: () async {
                await ref.read(onboardingDoneProvider.notifier).reset();
                if (context.mounted) context.go('/onboarding');
              },
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.school_outlined),
                title: Text(AppRu.showOnboarding),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            EcoCard(
              onTap: () => context.push('/legal/tos'),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.description_outlined),
                title: Text(AppRu.tos),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            EcoCard(
              onTap: () => context.push('/legal/privacy'),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text(AppRu.privacyPolicy),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            EcoCard(
              onTap: () => launchUrl(Uri.parse('mailto:eco@university.ru')),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.support_agent_outlined),
                title: Text(AppRu.support),
                subtitle: Text('eco@university.ru'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            EcoCard(
              onTap: () => launchUrl(
                Uri.parse('https://play.google.com/store'),
                mode: LaunchMode.externalApplication,
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.star_outline_rounded),
                title: Text(AppRu.rateApp),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 10),
            EcoCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text(AppRu.about),
                subtitle: Text(
                  AppRu.aboutBody,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.mutedDark
                        : AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppRu.versionLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(AppRu.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _logout(context, ref, everywhere: true),
              child: const Text(AppRu.logoutEverywhere),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _deleteAccount(context, ref),
              child: const Text(
                AppRu.deleteAccount,
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.accentDeep)
          : const Icon(Icons.circle_outlined, color: AppColors.muted),
      onTap: onTap,
    );
  }
}
