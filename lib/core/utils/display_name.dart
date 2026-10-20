import '../l10n/app_ru.dart';

/// Человекочитаемое имя: чинит «????» / пустые / дефолтные значения из БД.
String displayNameFor({
  required String? fullName,
  String? role,
}) {
  final cleaned = (fullName ?? '').trim();
  final looksBroken = cleaned.isEmpty ||
      cleaned == 'Student' ||
      RegExp(r'^[\?�\uFFFD\s.]+$', unicode: true).hasMatch(cleaned) ||
      (cleaned == 'Студент' && role != null && role != 'student') ||
      (cleaned.toLowerCase() == 'admin' || cleaned.toLowerCase() == 'volunteer');

  if (!looksBroken) return cleaned;

  return switch (role) {
    'admin' => AppRu.roleAdmin,
    'volunteer' => AppRu.roleVolunteer,
    _ => AppRu.roleStudent,
  };
}

String roleLabelRu(String? role) => switch (role) {
      'admin' => AppRu.roleAdmin,
      'volunteer' => AppRu.roleVolunteer,
      _ => AppRu.roleStudent,
    };
