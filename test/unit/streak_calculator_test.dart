import 'package:campus_eco_tracker/core/utils/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateStreakDays', () {
    final now = DateTime(2026, 3, 24, 15);

    test('empty history is zero', () {
      expect(calculateStreakDays([], now: now), 0);
    });

    test('counts consecutive days including today', () {
      final dates = [
        DateTime(2026, 3, 24, 10),
        DateTime(2026, 3, 23, 9),
        DateTime(2026, 3, 22, 18),
      ];
      expect(calculateStreakDays(dates, now: now), 3);
    });

    test('allows gap only if today is missing but yesterday has activity', () {
      final dates = [
        DateTime(2026, 3, 23, 9),
        DateTime(2026, 3, 22, 18),
      ];
      expect(calculateStreakDays(dates, now: now), 2);
    });

    test('breaks on missing day', () {
      final dates = [
        DateTime(2026, 3, 24, 10),
        DateTime(2026, 3, 22, 18),
      ];
      expect(calculateStreakDays(dates, now: now), 1);
    });

    test('zero when last activity older than yesterday', () {
      final dates = [DateTime(2026, 3, 20, 10)];
      expect(calculateStreakDays(dates, now: now), 0);
    });
  });
}