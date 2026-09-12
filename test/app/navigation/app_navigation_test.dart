import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('starts on the home tab', (tester) async {
    await tester.pumpWidget(buildTestApp().app);
    await settle(tester);

    expect(find.text('차고가 비어 있어요'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between 홈, 기록 and 설정', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp().app);
    await settle(tester);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);
    expect(find.text('정비 기록이 없습니다'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    expect(find.text('환경'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await settle(tester);
    expect(find.text('차고가 비어 있어요'), findsOneWidget);
  });

  testWidgets('settings shows the active environment', (tester) async {
    await tester.pumpWidget(buildTestApp().app);
    await settle(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);

    expect(find.text('dev'), findsOneWidget);
  });
}
