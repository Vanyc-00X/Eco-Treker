import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../models/profile.dart';

class AuthRepository {
  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

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
  }) async {
    // Профиль создаёт триггер handle_new_user (SECURITY DEFINER).
    // Клиентский insert в profiles ломается на RLS до применения политик.
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // Если сессия уже есть — допишем имя (после confirm email сессии может не быть).
    if (response.session != null && response.user != null) {
      try {
        await supabase.from('profiles').update({
          'full_name': fullName,
          'email': email,
        }).eq('id', response.user!.id);
      } catch (_) {
        // Профиль мог ещё не появиться — не блокируем регистрацию.
      }
    }
    return response;
  }

  Future<void> signOut() => supabase.auth.signOut();

  Future<Profile?> fetchProfile([String? userId]) async {
    final id = userId ?? currentUser?.id;
    if (id == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile> ensureProfile({
    required String fullName,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    final existing = await fetchProfile(user.id);
    if (existing != null) return existing;

    await supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email ?? '',
      'full_name': fullName,
      'role': 'student',
    });

    final created = await fetchProfile(user.id);
    if (created == null) {
      throw StateError('Failed to create profile');
    }
    return created;
  }
}