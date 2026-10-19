import 'dart:math';

/// Генерирует ротируемый Eco-ID токен (не UUID профиля).
String generateQrToken({int bytes = 24}) {
  final rng = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Полезная нагрузка QR: префикс + токен (без user id).
String buildEcoQrPayload(String qrToken) => 'eco:$qrToken';

/// Проверяет формат payload сканера.
bool isValidEcoQrPayload(String data) {
  if (!data.startsWith('eco:')) return false;
  final token = data.substring(4);
  return token.length >= 16 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(token);
}