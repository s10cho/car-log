import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// Registration asks one question at a time.
///
/// The point of the wizard is that a step only appears once the previous one is
/// answered, and that what has been answered stays visible. These check both,
/// plus that nothing is saved until the last step.
void main() {
  Future<void> openWizard(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '차량 등록'));
    await settle(tester);
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
  }

  Future<void> answerName(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField).first, name);
    await settle(tester);
  }

  testWidgets('opens on the body style question alone', (tester) async {
    await openWizard(tester, buildTestApp().app);

    expect(find.text('어떤 차인가요?'), findsOneWidget);
    // 다음 질문은 아직 보이지 않는다.
    expect(find.text('이 차를 뭐라고 부를까요?'), findsNothing);
    expect(find.text('지금 주행거리는요?'), findsNothing);
  });

  testWidgets('offers every body style and names the chosen one', (
    tester,
  ) async {
    await openWizard(tester, buildTestApp().app);

    expect(find.text('세단'), findsWidgets);
    await tester.tap(find.text('SUV').first);
    await settle(tester);

    expect(find.text('SUV'), findsWidgets);
  });

  testWidgets('reveals the next question only after answering', (tester) async {
    await openWizard(tester, buildTestApp().app);
    await next(tester);

    expect(find.text('이 차를 뭐라고 부를까요?'), findsOneWidget);
    // 이름이 비어 있으면 진행할 수 없다.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
          .onPressed,
      isNull,
    );

    await answerName(tester, '내 아반떼');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps answered questions visible as chips', (tester) async {
    await openWizard(tester, buildTestApp().app);
    await tester.tap(find.text('SUV').first);
    await settle(tester);
    await next(tester);
    await answerName(tester, '내 아반떼');
    await next(tester);

    // 답한 것이 사라지지 않는다.
    expect(find.text('SUV'), findsWidgets);
    expect(find.text('내 아반떼'), findsWidgets);
    expect(find.text('지금 주행거리는요?'), findsOneWidget);
  });

  testWidgets('shows the mileage formatted as it is typed', (tester) async {
    await openWizard(tester, buildTestApp().app);
    await next(tester);
    await answerName(tester, '아반떼');
    await next(tester);

    await tester.enterText(find.byType(TextField).first, '47250');
    await settle(tester);

    expect(find.text('47,250 km'), findsOneWidget);
  });

  testWidgets('refuses an implausible odometer reading', (tester) async {
    await openWizard(tester, buildTestApp().app);
    await next(tester);
    await answerName(tester, '아반떼');
    await next(tester);
    await tester.enterText(find.byType(TextField).first, '9000000');
    await settle(tester);

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('saves nothing until the last step', (tester) async {
    final (:app, :container) = buildTestApp();
    await openWizard(tester, app);
    await next(tester);
    await answerName(tester, '아반떼');
    await next(tester);
    await tester.enterText(find.byType(TextField).first, '32000');
    await settle(tester);
    await next(tester);

    expect(find.text('거의 끝났어요'), findsOneWidget);
    expect(await readVehicles(container), isEmpty);
  });

  testWidgets('finishing puts the car in the garage', (tester) async {
    final (:app, :container) = buildTestApp();
    await openWizard(tester, app);
    await tester.tap(find.text('SUV').first);
    await settle(tester);
    await next(tester);
    await answerName(tester, '내 아반떼');
    await next(tester);
    await tester.enterText(find.byType(TextField).first, '47250');
    await settle(tester);
    await next(tester);
    await tester.tap(find.widgetWithText(FilledButton, '차고에 넣기'));
    await settleAnimations(tester);

    final vehicles = await readVehicles(container);
    expect(vehicles, hasLength(1));
    expect(vehicles.single.displayName, '내 아반떼');
    expect(vehicles.single.currentMileage, 47250);
    expect(vehicles.single.bodyStyle, 'suv');

    // 등록한 차가 바로 차고에 보인다.
    expect(find.text('내 아반떼'), findsWidgets);
    expect(find.text('47,250 km'), findsWidgets);
  });

  testWidgets('optional details are saved when filled in', (tester) async {
    final (:app, :container) = buildTestApp();
    await openWizard(tester, app);
    await next(tester);
    await answerName(tester, '아반떼');
    await next(tester);
    await tester.enterText(find.byType(TextField).first, '32000');
    await settle(tester);
    await next(tester);

    await tester.enterText(find.widgetWithText(TextField, '제조사'), '현대');
    await tester.enterText(find.widgetWithText(TextField, '연식'), '2021');
    await tester.tap(find.widgetWithText(FilledButton, '차고에 넣기'));
    await settleAnimations(tester);

    final vehicle = (await readVehicles(container)).single;
    expect(vehicle.manufacturer, '현대');
    expect(vehicle.modelYear, 2021);
  });

  testWidgets('going back returns to the previous question', (tester) async {
    await openWizard(tester, buildTestApp().app);
    await next(tester);
    await answerName(tester, '아반떼');
    await next(tester);
    expect(find.text('지금 주행거리는요?'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('이 차를 뭐라고 부를까요?'), findsOneWidget);
  });

  testWidgets('backing out of the first question leaves the wizard', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await openWizard(tester, app);

    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('어떤 차인가요?'), findsNothing);
    expect(find.text('차고가 비어 있어요'), findsOneWidget);
    expect(await readVehicles(container), isEmpty);
  });
}
