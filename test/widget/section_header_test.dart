import 'package:campus_eco_tracker/core/l10n/app_ru.dart';
import 'package:campus_eco_tracker/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SectionHeader shows Russian title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: AppRu.recycleHub,
            subtitle: AppRu.recycleHubSubtitle,
            serif: true,
          ),
        ),
      ),
    );

    expect(find.text(AppRu.recycleHub), findsOneWidget);
    expect(find.text(AppRu.recycleHubSubtitle), findsOneWidget);
  });
}