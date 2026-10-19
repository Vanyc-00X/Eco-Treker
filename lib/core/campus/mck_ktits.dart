/// Справочник МЦК-КТИТС (https://mck-ktits.ru/) для регистрации и профиля.
abstract final class MckKtits {
  static const shortName = 'МЦК-КТИТС';
  static const fullName =
      'Международный центр компетенций — Казанский техникум информационных технологий и связи';
  static const city = 'Казань';
  static const address = 'ул. Бари Галеева, д. 3-А';
  static const phone = '+7 (843) 203-55-55';
  static const email = 'mck.ktits@tatar.ru';
  static const site = 'https://mck-ktits.ru/';
  static const supportEmail = 'mck.ktits@tatar.ru';

  /// Корпус техникума (Казань).
  static const campusLat = 55.8304;
  static const campusLng = 49.1328;

  static const courses = [1, 2, 3, 4];

  static const departments = <String>[
    'Базовая профессиональная подготовка',
    'Информационные технологии',
    'Сетевые технологии',
    'Информационная безопасность и связь',
  ];

  /// Специальности и квалификации приёма (по данным mck-ktits.ru / priem).
  static const specialties = <MckSpecialty>[
    MckSpecialty(
      code: '09.02.01',
      title: 'Компьютерные системы и комплексы',
      qualification: 'Специалист по компьютерным системам',
      department: 'Сетевые технологии',
    ),
    MckSpecialty(
      code: '09.02.06',
      title: 'Сетевое и системное администрирование',
      qualification: 'Системный администратор',
      department: 'Сетевые технологии',
    ),
    MckSpecialty(
      code: '09.02.07',
      title: 'Информационные системы и программирование',
      qualification: 'Программист',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.07',
      title: 'Информационные системы и программирование',
      qualification: 'Разработчик веб и мультимедийных приложений',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.07',
      title: 'Информационные системы и программирование',
      qualification: 'Специалист по информационным системам',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.08',
      title: 'Интеллектуальные интегрированные системы',
      qualification: 'Техник по интеллектуальным интегрированным системам',
      department: 'Сетевые технологии',
    ),
    MckSpecialty(
      code: '09.02.09',
      title: 'Веб-разработка',
      qualification: 'Разработчик веб-приложений (клиент)',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.09',
      title: 'Веб-разработка',
      qualification: 'Разработчик веб-приложений (сервер)',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.11',
      title: 'Разработка и управление ПО',
      qualification: 'Программист (C#)',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.11',
      title: 'Разработка и управление ПО',
      qualification: 'Программист (1С)',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.11',
      title: 'Разработка и управление ПО',
      qualification: 'Программист (веб-приложение)',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '09.02.13',
      title: 'Интеграция решений с применением ИИ',
      qualification: 'Специалист по работе с ИИ',
      department: 'Информационные технологии',
    ),
    MckSpecialty(
      code: '10.02.05',
      title: 'Обеспечение информационной безопасности АС',
      qualification: 'Техник по защите информации',
      department: 'Информационная безопасность и связь',
    ),
    MckSpecialty(
      code: '11.02.12',
      title: 'Почтовая связь',
      qualification: 'Специалист почтовой связи',
      department: 'Информационная безопасность и связь',
    ),
    MckSpecialty(
      code: '11.02.15',
      title: 'Инфокоммуникационные сети и системы связи',
      qualification: 'Специалист по монтажу и обслуживанию телекоммуникаций',
      department: 'Информационная безопасность и связь',
    ),
  ];

  /// Отделение по курсу: 1 курс — базовая подготовка, иначе профиль специальности.
  static String departmentFor({
    required int course,
    required MckSpecialty specialty,
  }) {
    if (course <= 1) return departments.first;
    return specialty.department;
  }

  static MckSpecialty? findByLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    final t = label.trim();
    for (final s in specialties) {
      if (s.label == t || s.shortLabel == t) return s;
    }
    return null;
  }
}

class MckSpecialty {
  const MckSpecialty({
    required this.code,
    required this.title,
    required this.qualification,
    required this.department,
  });

  final String code;
  final String title;
  final String qualification;
  final String department;

  /// Полная подпись для профиля / БД.
  String get label => '$code $title — $qualification';

  /// Короткая подпись в выпадающем списке.
  String get shortLabel => '$code · $qualification';
}
