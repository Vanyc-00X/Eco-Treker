import 'package:campus_eco_tracker/features/challenges/models/challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Challenge', () {
    test('typeLabel and timeLeftLabel are Russian', () {
      final challenge = Challenge(
        id: 'c1',
        title: 'Неделя пластика',
        description: 'Сдайте 5 кг',
        challengeType: 'weekly',
        rewardPoints: 100,
        startsAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(days: 3, hours: 2)),
        targetKg: 5,
      );

      expect(challenge.typeLabel, 'Еженедельный');
      expect(challenge.timeLeftLabel, contains('дн. осталось'));
    });
  });
}