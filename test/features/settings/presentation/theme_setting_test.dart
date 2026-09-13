import 'package:car_log/features/settings/data/theme_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
  }

  ThemeMode renderedMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  testWidgets('the app opens light, whatever the phone is set to', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp().app);
    await settle(tester);

    expect(renderedMode(tester), ThemeMode.light);
  });

  testWidgets('the theme picked in settings is applied and kept', (
    tester,
  ) async {
    final harness = buildTestApp();
    await tester.pumpWidget(harness.app);
    await settle(tester);
    await openSettings(tester);

    expect(find.widgetWithText(ListTile, '라이트'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, '화면 테마'));
    await settle(tester);

    await tester.tap(find.widgetWithText(ListTile, '다크'));
    await settle(tester);

    expect(renderedMode(tester), ThemeMode.dark);
    expect(find.widgetWithText(ListTile, '다크'), findsOneWidget);
    expect(
      await harness.container.read(themeSettingsRepositoryProvider).read(),
      ThemeMode.dark,
      reason: '다음 실행에서도 다크로 열려야 한다',
    );
  });

  testWidgets('following the system is still on offer', (tester) async {
    final harness = buildTestApp();
    await tester.pumpWidget(harness.app);
    await settle(tester);
    await openSettings(tester);

    await tester.tap(find.widgetWithText(ListTile, '화면 테마'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, '시스템 설정 따르기'));
    await settle(tester);

    expect(renderedMode(tester), ThemeMode.system);
  });

  test('a value written by a newer build falls back to the default', () {
    expect(ThemeSettingsRepository.parse('solarized'), ThemeMode.light);
    expect(ThemeSettingsRepository.parse(null), ThemeMode.light);
    expect(ThemeSettingsRepository.parse('dark'), ThemeMode.dark);
  });
}
