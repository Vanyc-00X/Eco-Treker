import 'package:campus_eco_tracker/core/utils/display_name.dart';
import 'package:campus_eco_tracker/features/auth/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('displayNameFor', () {
    test('keeps normal Russian names', () {
      expect(
        displayNameFor(fullName: 'Иван Петров', role: 'student'),
        'Иван Петров',
      );
    });

    test('replaces question marks for admin/volunteer', () {
      expect(
        displayNameFor(fullName: '????', role: 'admin'),
        'Администратор',
      );
      expect(
        displayNameFor(fullName: '???', role: 'volunteer'),
        'Волонтёр',
      );
    });

    test('replaces English role placeholders', () {
      expect(displayNameFor(fullName: 'admin', role: 'admin'), 'Администратор');
      expect(
        displayNameFor(fullName: 'Volunteer', role: 'volunteer'),
        'Волонтёр',
      );
    });
  });

  group('Profile.displayName', () {
    test('uses role fallback when full_name is broken', () {
      final profile = Profile.fromJson({
        'id': 'a1',
        'email': 'a@b.ru',
        'full_name': '????',
        'role': 'admin',
        'eco_level': 'eco_novice',
        'green_points': 0,
        'total_kg': 0,
        'co2_saved_kg': 0,
      });
      expect(profile.displayName, 'Администратор');
    });
  });
}
