import 'package:campus_eco_tracker/core/utils/qr_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('qr_token', () {
    test('generateQrToken returns hex of expected length', () {
      final token = generateQrToken(bytes: 16);
      expect(token.length, 32);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(token), isTrue);
    });

    test('buildEcoQrPayload prefixes eco:', () {
      expect(buildEcoQrPayload('abcd'), 'eco:abcd');
    });

    test('isValidEcoQrPayload accepts rotatable tokens only', () {
      final token = generateQrToken();
      expect(isValidEcoQrPayload(buildEcoQrPayload(token)), isTrue);
      expect(isValidEcoQrPayload(token), isFalse);
      expect(isValidEcoQrPayload('eco:short'), isFalse);
      // UUID профиля без префикса — невалидно
      expect(
        isValidEcoQrPayload('550e8400-e29b-41d4-a716-446655440000'),
        isFalse,
      );
    });
  });
}