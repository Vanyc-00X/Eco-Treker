import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../core/utils/qr_token.dart';
import '../models/profile.dart';

class AuthRepository {
  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  bool get isEmailConfirmed {
    final user = currentUser;
    if (user == null) return true;
    return user.emailConfirmedAt != null;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? groupName,
    String? facultyName,
    int? course,
    String? phone,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'group_name': groupName,
        'faculty_name': facultyName,
        'course': course,
      },
      emailRedirectTo: null,
    );

    // Письмо подтверждения: повторная отправка (если Confirm email включён).
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (_) {}

    var session = response.session;
    var user = response.user;

    // Если сессии нет (Confirm email) — пробуем сразу войти
    // (сработает после SQL auto_confirm или при выключенном Confirm).
    if (session == null) {
      try {
        final signedIn = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        session = signedIn.session;
        user = signedIn.user ?? user;
      } catch (_) {}
    }

    if (user != null) {
      try {
        await supabase.from('profiles').update({
          'full_name': fullName,
          'email': email,
          'group_name': groupName,
          'faculty_name': facultyName,
          'course': course,
          'phone': phone,
          'privacy_consent_at': DateTime.now().toUtc().toIso8601String(),
          'tos_accepted_at': DateTime.now().toUtc().toIso8601String(),
          'qr_token': generateQrToken(),
          'qr_token_rotated_at': DateTime.now().toUtc().toIso8601String(),
          'verified': false,
        }).eq('id', user.id);
      } catch (_) {}
    }

    return AuthResponse(session: session, user: user);
  }

  Future<void> resendSignupEmail(String email) {
    return supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  Future<void> signOut({bool everywhere = false}) {
    return supabase.auth.signOut(
      scope: everywhere ? SignOutScope.global : SignOutScope.local,
    );
  }

  Future<void> resetPassword(String email) {
    return supabase.auth.resetPasswordForEmail(email);
  }

  /// Email-алиас для входа по телефону (без SMS-провайдера).
  static String phoneAliasEmail(String phoneE164) {
    final digits = phoneE164.replaceAll(RegExp(r'\D'), '');
    return 'p$digits@phone.campus.local';
  }

  static String phoneAliasPassword(String phoneE164) {
    final digits = phoneE164.replaceAll(RegExp(r'\D'), '');
    return 'Phone${digits}Aa1!';
  }

  bool _lastPhoneOtpLocal = false;

  /// Запрос OTP. Локальный RPC (без Twilio); при наличии SMS-провайдера — SMS.
  /// Возвращает код, если его нужно показать на экране.
  Future<String?> sendPhoneOtp(String phoneE164) async {
    // Основной путь: OTP в БД (работает без SMS-провайдера).
    try {
      final code = await supabase.rpc(
        'request_phone_otp',
        params: {'p_phone': phoneE164},
      );
      _lastPhoneOtpLocal = true;
      return code is String ? code : '$code';
    } catch (rpcError) {
      // Fallback: нативный Phone Auth Supabase (нужен Twilio и т.п.)
      try {
        await supabase.auth.signInWithOtp(phone: phoneE164);
        _lastPhoneOtpLocal = false;
        return null;
      } catch (_) {
        throw StateError(
          'Не удалось отправить код. Выполните SQL 20260403_fix_auth.sql '
          'или настройте Phone Auth в Supabase.\n$rpcError',
        );
      }
    }
  }

  /// Проверка OTP + вход/регистрация.
  Future<AuthResponse> verifyPhoneOtp({
    required String phoneE164,
    required String token,
  }) async {
    if (!_lastPhoneOtpLocal) {
      try {
        return await supabase.auth.verifyOTP(
          phone: phoneE164,
          token: token,
          type: OtpType.sms,
        );
      } catch (_) {
        // fall through to local
      }
    }

    final ok = await supabase.rpc(
      'verify_phone_otp',
      params: {'p_phone': phoneE164, 'p_code': token.trim()},
    );
    if (ok != true) {
      throw StateError('Неверный код');
    }

    final email = phoneAliasEmail(phoneE164);
    final password = phoneAliasPassword(phoneE164);

    try {
      final signedIn = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _touchPhoneProfile(signedIn.user?.id, phoneE164);
      return signedIn;
    } catch (_) {
      final created = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': 'Пользователь $phoneE164',
          'phone': phoneE164,
        },
      );
      if (created.session != null) {
        await _touchPhoneProfile(created.user?.id, phoneE164);
        return created;
      }
      final signedIn = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _touchPhoneProfile(signedIn.user?.id, phoneE164);
      return signedIn;
    }
  }

  Future<void> _touchPhoneProfile(String? userId, String phoneE164) async {
    if (userId == null) return;
    final email = phoneAliasEmail(phoneE164);
    final name = 'Пользователь $phoneE164';
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'full_name': name,
        'phone': phoneE164,
        'role': 'student',
        'qr_token': generateQrToken(),
        'qr_token_rotated_at': DateTime.now().toUtc().toIso8601String(),
        'verified': false,
      });
    } catch (_) {
      try {
        await ensureProfile(fullName: name);
        await supabase.from('profiles').update({
          'phone': phoneE164,
          'email': email,
          'full_name': name,
        }).eq('id', userId);
      } catch (_) {}
    }
  }

  Future<void> resetPasswordWithPhone({
    required String phoneE164,
  }) async {
    await sendPhoneOtp(phoneE164);
  }

  Future<Profile> updateProfile({
    required String fullName,
    String? phone,
    int? course,
    String? groupName,
    String? facultyName,
    DateTime? dateOfBirth,
    String? profileVisibility,
    bool? showInLeaderboard,
    String? accentColor,
    bool? mfaEnabled,
    Map<String, dynamic>? notificationPrefs,
  }) async {
    final user = currentUser;
    if (user == null) throw StateError('Not authenticated');

    final patch = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'course': course,
      'group_name': groupName,
      'faculty_name': facultyName,
      'last_active_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (dateOfBirth != null) {
      patch['date_of_birth'] = dateOfBirth.toIso8601String().substring(0, 10);
    }
    if (profileVisibility != null) {
      patch['profile_visibility'] = profileVisibility;
    }
    if (showInLeaderboard != null) {
      patch['show_in_leaderboard'] = showInLeaderboard;
    }
    if (accentColor != null) patch['accent_color'] = accentColor;
    if (mfaEnabled != null) patch['mfa_enabled'] = mfaEnabled;
    if (notificationPrefs != null) {
      patch['notification_prefs'] = notificationPrefs;
    }

    await supabase.from('profiles').update(patch).eq('id', user.id);
    final updated = await fetchProfile(user.id);
    if (updated == null) throw StateError('Failed to reload profile');
    return updated;
  }

  Future<String?> uploadAvatar(Uint8List bytes, String ext) async {
    final user = currentUser;
    if (user == null) throw StateError('Not authenticated');
    final path = '${user.id}/avatar.$ext';
    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );
    final url = supabase.storage.from('avatars').getPublicUrl(path);
    await supabase.from('profiles').update({'avatar_url': url}).eq('id', user.id);
    return url;
  }

  Future<Profile?> fetchProfile([String? userId]) async {
    final id = userId ?? currentUser?.id;
    if (id == null) return null;

    final data =
        await supabase.from('profiles').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  /// Телефон из email-алиаса `p7900...@phone.campus.local`.
  static String? phoneFromAliasEmail(String? email) {
    if (email == null) return null;
    final m = RegExp(r'^p(\d+)@phone\.campus\.local$', caseSensitive: false)
        .firstMatch(email.trim());
    if (m == null) return null;
    return '+${m.group(1)}';
  }

  Future<Profile> ensureProfile({required String fullName}) async {
    final user = currentUser;
    if (user == null) throw StateError('Not authenticated');

    final existing = await fetchProfile(user.id);
    if (existing != null) return existing;

    final meta = user.userMetadata ?? {};
    final phone = user.phone ??
        meta['phone']?.toString() ??
        phoneFromAliasEmail(user.email);
    final email = (user.email != null && user.email!.isNotEmpty)
        ? user.email!
        : (phone != null && phone.isNotEmpty)
            ? phoneAliasEmail(phone)
            : '';

    await supabase.from('profiles').upsert({
      'id': user.id,
      'email': email,
      'full_name': fullName.trim().isEmpty ? 'Студент' : fullName.trim(),
      'phone': phone,
      'role': 'student',
      'qr_token': generateQrToken(),
      'qr_token_rotated_at': DateTime.now().toUtc().toIso8601String(),
      'verified': false,
    });

    final created = await fetchProfile(user.id);
    if (created == null) throw StateError('Failed to create profile');
    return created;
  }

  /// Профиль текущего пользователя; создаёт, если триггер не сработал.
  Future<Profile?> fetchOrEnsureProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final existing = await fetchProfile(user.id);
    if (existing != null) return existing;

    final meta = user.userMetadata ?? {};
    final phone = user.phone ??
        meta['phone']?.toString() ??
        phoneFromAliasEmail(user.email);
    final metaName = meta['full_name']?.toString().trim();
    final name = (metaName != null && metaName.isNotEmpty)
        ? metaName
        : (phone != null && phone.isNotEmpty)
            ? 'Пользователь $phone'
            : 'Студент';

    try {
      return await ensureProfile(fullName: name);
    } catch (_) {
      return null;
    }
  }

  Future<String> ensureQrToken() async {
    final profile = await fetchProfile();
    if (profile == null) throw StateError('Not authenticated');
    if (profile.qrToken != null && profile.qrToken!.isNotEmpty) {
      return profile.qrToken!;
    }
    return rotateQrToken();
  }

  Future<String> rotateQrToken() async {
    final user = currentUser;
    if (user == null) throw StateError('Not authenticated');

    try {
      final result = await supabase.rpc('rotate_qr_token');
      if (result is String && result.isNotEmpty) return result;
    } catch (_) {}

    final token = generateQrToken();
    await supabase.from('profiles').update({
      'qr_token': token,
      'qr_token_rotated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
    return token;
  }

  Future<void> softDeleteAccount() async {
    try {
      await supabase.rpc('soft_delete_account');
    } catch (_) {
      final user = currentUser;
      if (user == null) return;
      await supabase.from('profiles').update({
        'full_name': 'Удалённый пользователь',
        'show_in_leaderboard': false,
        'profile_visibility': 'private',
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'qr_token': null,
      }).eq('id', user.id);
    }
    await signOut(everywhere: true);
  }

  Future<void> touchLastActive() async {
    try {
      await supabase.rpc('touch_last_active');
    } catch (_) {}
  }
}
