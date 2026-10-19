import 'package:campus_eco_tracker/core/tips/eco_tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EcoTips rotates by day', () {
    final a = EcoTips.forDay(DateTime(2026, 3, 24));
    final b = EcoTips.forDay(DateTime(2026, 3, 25));
    expect(a, isNotEmpty);
    expect(b, isNotEmpty);
    expect(EcoTips.items.contains(a), isTrue);
    expect(a == b, isFalse);
  });
}