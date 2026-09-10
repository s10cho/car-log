import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app() => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(AppConfig.of(AppEnvironment.dev)),
  ],
  child: const CarLogApp(),
);

void main() {
  testWidgets('starts on the home tab with the first-use empty state', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('아직 등록된 차량이 없습니다'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between 홈, 기록 and 설정', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('정비 기록이 없습니다'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('환경'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 차량이 없습니다'), findsOneWidget);
  });

  testWidgets('settings shows the active environment', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('dev'), findsOneWidget);
  });
}
