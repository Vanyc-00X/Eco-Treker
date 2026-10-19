import 'package:campus_eco_tracker/core/utils/password_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordValidator', () {
    test('rejects short and common passwords', () {
      expect(PasswordValidator.validate('Ab1'), isNotNull);
      expect(PasswordValidator.validate('password'), isNotNull);
      expect(PasswordValidator.validate('12345678'), isNotNull);
    });

    test('accepts strong password', () {
      expect(PasswordValidator.validate('EcoPass1'), isNull);
    });
  });
}
