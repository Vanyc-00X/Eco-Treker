/// Правила пароля по ТЗ.
abstract final class PasswordValidator {
  static const minLength = 8;

  static const commonPasswords = {
    '12345678',
    'password',
    'qwerty',
    'qwerty12',
    'qwerty123',
    '123456789',
    '11111111',
    'password1',
    'abc12345',
  };

  /// null если OK, иначе сообщение об ошибке.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Минимум $minLength символов';
    }
    if (!RegExp(r'[A-ZА-Я]').hasMatch(password)) {
      return 'Нужна заглавная буква';
    }
    if (!RegExp(r'[a-zа-я]').hasMatch(password)) {
      return 'Нужна строчная буква';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Нужна цифра';
    }
    if (commonPasswords.contains(password.toLowerCase())) {
      return 'Слишком простой пароль';
    }
    return null;
  }

  static bool hasSpecialChar(String password) =>
      RegExp(r'[!@#$%^&*]').hasMatch(password);
}
