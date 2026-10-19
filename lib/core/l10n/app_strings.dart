import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/app_prefs.dart';
import 'app_en.dart';
import 'app_ru.dart';

/// Простая i18n-обёртка поверх существующих констант.
abstract final class AppStrings {
  static bool isEn(String code) => code == 'en';

  static String t(String locale, {required String ru, required String en}) =>
      isEn(locale) ? en : ru;
}

final localeCodeProvider =
    NotifierProvider<LocaleCodeNotifier, String>(LocaleCodeNotifier.new);

class LocaleCodeNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(sharedPreferencesProvider).getString(kLocaleCode) ?? 'ru';
  }

  Future<void> setLocale(String code) async {
    await ref.read(sharedPreferencesProvider).setString(kLocaleCode, code);
    state = code;
  }
}

/// Хелпер для экранов: текущий набор строк.
class L10n {
  L10n(this.locale);
  final String locale;

  bool get isEn => locale == 'en';

  String get appTitle => isEn ? AppEn.appTitle : AppRu.appTitle;
  String get signIn => isEn ? AppEn.signIn : AppRu.signIn;
  String get createAccount => isEn ? AppEn.createAccount : AppRu.createAccount;
  String get settings => isEn ? AppEn.settings : AppRu.settings;
  String get about => isEn ? AppEn.about : AppRu.about;
  String get logout => isEn ? AppEn.logout : AppRu.logout;
}
