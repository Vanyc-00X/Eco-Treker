import 'package:flutter/material.dart';

import '../../../core/l10n/app_ru.dart';

/// Заглушка IoT по плану 1A.
class IotStubCard extends StatelessWidget {
  const IotStubCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.sensors_outlined),
        title: Text(AppRu.iotStub),
        subtitle: Text(
          'Автофиксация сдачи через датчики будет подключена позже.',
        ),
      ),
    );
  }
}
