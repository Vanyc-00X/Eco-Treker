/// Калькулятор баллов и CO₂ по ТЗ.
class PointsResult {
  const PointsResult({
    required this.basePoints,
    required this.points,
    required this.co2Kg,
    required this.multiplier,
  });

  final int basePoints;
  final int points;
  final double co2Kg;
  final double multiplier;
}

abstract final class PointsCalculator {
  static const challengeBonus = 1.5;
  static const firstDropBonus = 2.0;
  static const weekendBonus = 1.2;
  static const peakHoursBonus = 1.1;

  static double computeMultiplier({
    required DateTime when,
    required bool inActiveChallenge,
    required bool isFirstDrop,
  }) {
    var m = 1.0;
    if (isFirstDrop) m *= firstDropBonus;
    if (inActiveChallenge) m *= challengeBonus;
    if (when.weekday == DateTime.saturday || when.weekday == DateTime.sunday) {
      m *= weekendBonus;
    }
    final hour = when.hour;
    if (hour >= 12 && hour < 14) {
      m *= peakHoursBonus;
    }
    return double.parse(m.toStringAsFixed(2));
  }

  static PointsResult calculate({
    required double weightKg,
    required int pointsPerKg,
    required double co2PerKg,
    required double multiplier,
  }) {
    final base = (weightKg * pointsPerKg).round();
    final points = (weightKg * pointsPerKg * multiplier).round();
    final co2 =
        double.parse((weightKg * co2PerKg * multiplier).toStringAsFixed(3));
    return PointsResult(
      basePoints: base,
      points: points,
      co2Kg: co2,
      multiplier: multiplier,
    );
  }
}
