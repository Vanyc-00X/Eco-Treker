import 'package:campus_eco_tracker/core/l10n/app_ru.dart';
import 'package:campus_eco_tracker/features/auth/data/auth_repository.dart';
import 'package:campus_eco_tracker/features/auth/presentation/login_screen.dart';
import 'package:campus_eco_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

void main() {
  testWidgets('LoginScreen shows Russian copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text(AppRu.appTitle), findsOneWidget);
    expect(find.text(AppRu.signIn), findsOneWidget);
    expect(find.text(AppRu.newHere), findsOneWidget);
  });
}