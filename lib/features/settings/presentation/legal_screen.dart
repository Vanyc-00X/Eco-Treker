import 'package:flutter/material.dart';

import '../../../core/l10n/app_ru.dart';
import '../../../shared/widgets/app_page.dart';

enum LegalDoc { tos, privacy }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final title = doc == LegalDoc.tos ? AppRu.tos : AppRu.privacyPolicy;
    final body = doc == LegalDoc.tos
        ? _tos
        : _privacy;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppPage(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(body, style: const TextStyle(height: 1.45)),
        ),
      ),
    );
  }

  static const _tos = '''
Пользовательское соглашение Campus Eco-Tracker

1. Сервис предназначен для студентов кампуса и учитывает сдачу вторсырья, челленджи и рейтинги.
2. Пользователь обязуется предоставлять достоверные данные и не злоупотреблять системой начисления баллов.
3. Заявки с фото проходят модерацию волонтёрами.
4. Администрация вправе изменять коэффициенты и правила челленджей с уведомлением в приложении.
5. Используя приложение, вы принимаете условия настоящего соглашения.
''';

  static const _privacy = '''
Политика конфиденциальности Campus Eco-Tracker

1. Мы обрабатываем ФИО, учебную группу, факультет, контакты и данные об эко-активности.
2. Данные используются для начисления баллов, рейтингов и связи с пунктами сбора.
3. Удаление аккаунта анонимизирует профиль; аналитические агрегаты могут храниться без ПДн.
4. Срок хранения данных после удаления — до 30 дней для возможности восстановления.
5. Контакт поддержки: eco@university.ru
''';
}
