import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingDone = 'onboarding_done_v1';
const kLocaleCode = 'locale_code_v1';
const _kAccent = 'accent_color_v1';
const _kNotifChallenges = 'notif_challenges';
const _kNotifReminders = 'notif_reminders';
const _kNotifRanking = 'notif_ranking';
const _kNotifSystem = 'notif_system';
const _kNotifPromos = 'notif_promos';
const _kRankHistory = 'rank_history_v1';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final onboardingDoneProvider =
    NotifierProvider<OnboardingDoneNotifier, bool>(OnboardingDoneNotifier.new);

class OnboardingDoneNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  Future<void> complete() async {
    await ref.read(sharedPreferencesProvider).setBool(_kOnboardingDone, true);
    state = true;
  }

  Future<void> reset() async {
    await ref.read(sharedPreferencesProvider).setBool(_kOnboardingDone, false);
    state = false;
  }
}

final accentColorProvider =
    NotifierProvider<AccentColorNotifier, String>(AccentColorNotifier.new);

class AccentColorNotifier extends Notifier<String> {
  @override
  String build() =>
      ref.watch(sharedPreferencesProvider).getString(_kAccent) ?? 'green';

  Future<void> setAccent(String value) async {
    await ref.read(sharedPreferencesProvider).setString(_kAccent, value);
    state = value;
  }
}

class NotificationPrefs {
  const NotificationPrefs({
    this.challenges = true,
    this.reminders = true,
    this.ranking = true,
    this.system = true,
    this.promos = false,
  });

  final bool challenges;
  final bool reminders;
  final bool ranking;
  final bool system;
  final bool promos;

  NotificationPrefs copyWith({
    bool? challenges,
    bool? reminders,
    bool? ranking,
    bool? system,
    bool? promos,
  }) {
    return NotificationPrefs(
      challenges: challenges ?? this.challenges,
      reminders: reminders ?? this.reminders,
      ranking: ranking ?? this.ranking,
      system: system ?? this.system,
      promos: promos ?? this.promos,
    );
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  NotificationPrefsNotifier.new,
);

class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    final p = ref.watch(sharedPreferencesProvider);
    return NotificationPrefs(
      challenges: p.getBool(_kNotifChallenges) ?? true,
      reminders: p.getBool(_kNotifReminders) ?? true,
      ranking: p.getBool(_kNotifRanking) ?? true,
      system: p.getBool(_kNotifSystem) ?? true,
      promos: p.getBool(_kNotifPromos) ?? false,
    );
  }

  Future<void> update(NotificationPrefs next) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setBool(_kNotifChallenges, next.challenges);
    await p.setBool(_kNotifReminders, next.reminders);
    await p.setBool(_kNotifRanking, next.ranking);
    await p.setBool(_kNotifSystem, next.system);
    await p.setBool(_kNotifPromos, next.promos);
    state = next;
  }
}

Future<void> clearLocalCache(SharedPreferences prefs) async {
  final keys = prefs.getKeys().toList();
  for (final k in keys) {
    if (k == _kOnboardingDone) continue;
    await prefs.remove(k);
  }
}

Future<void> saveRankSnapshot(SharedPreferences prefs, int rank) async {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final raw = prefs.getStringList(_kRankHistory) ?? [];
  raw.removeWhere((e) => e.startsWith('$today|'));
  raw.add('$today|$rank');
  if (raw.length > 60) raw.removeRange(0, raw.length - 60);
  await prefs.setStringList(_kRankHistory, raw);
}

List<MapEntry<String, int>> loadRankHistory(SharedPreferences prefs) {
  final raw = prefs.getStringList(_kRankHistory) ?? [];
  return raw.map((e) {
    final parts = e.split('|');
    return MapEntry(parts[0], int.tryParse(parts[1]) ?? 0);
  }).toList();
}
