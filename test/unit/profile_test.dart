import 'package:campus_eco_tracker/features/auth/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile', () {
    test('fromJson maps fields and Russian level labels', () {
      final profile = Profile.fromJson({
        'id': 'u1',
        'email': 'a@b.ru',
        'full_name': 'Иван',
        'role': 'student',
        'eco_level': 'forest_keeper',
        'green_points': 120,
        'total_kg': 4.5,
        'co2_saved_kg': 2.1,
        'qr_token': 'abc123',
      });

      expect(profile.id, 'u1');
      expect(profile.greenPoints, 120);
      expect(profile.qrToken, 'abc123');
      expect(profile.ecoLevelLabel, 'Хранитель леса');
      expect(profile.ecoLevelNumber, 2);
    });

    test('default level is Eco Novice in Russian', () {
      final profile = Profile.fromJson({'id': 'u2'});
      expect(profile.ecoLevelLabel, 'Эко-новичок');
      expect(profile.ecoLevelNumber, 1);
    });
  });
}