import 'package:campus_eco_tracker/core/utils/points_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PointsCalculator', () {
    test('plastic 1kg base = 50 points', () {
      final r = PointsCalculator.calculate(
        weightKg: 1,
        pointsPerKg: 50,
        co2PerKg: 1.5,
        multiplier: 1,
      );
      expect(r.points, 50);
      expect(r.co2Kg, 1.5);
    });

    test('first drop doubles points', () {
      final m = PointsCalculator.computeMultiplier(
        when: DateTime(2026, 3, 10, 10), // weekday morning
        inActiveChallenge: false,
        isFirstDrop: true,
      );
      expect(m, 2.0);
      final r = PointsCalculator.calculate(
        weightKg: 1,
        pointsPerKg: 50,
        co2PerKg: 1.5,
        multiplier: m,
      );
      expect(r.points, 100);
    });
  });
}
