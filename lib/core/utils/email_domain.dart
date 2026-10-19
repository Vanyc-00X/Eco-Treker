/// Валидация email (любой корректный адрес).
abstract final class EmailDomain {
  static final _re = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static bool isAllowed(String email) => validate(email) == null;

  /// null если OK, иначе сообщение об ошибке.
  static String? validate(String email) {
    final value = email.trim();
    if (value.isEmpty) return 'Обязательное поле';
    if (!_re.hasMatch(value)) return 'Некорректный email';
    return null;
  }
}
