import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// The form page now only edits an existing vehicle; registration goes through
/// the wizard (see vehicle_wizard_page_test.dart).
void main() {
  Future<ProviderContainer> openEditForm(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(
          displayName: '아반떼',
          currentMileage: 32000,
          bodyStyle: 'sedan',
          paintColor: 'blue',
          manufacturer: '현대',
        );

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await settle(tester);
    await tester.tap(find.text('정보 수정'));
    await settle(tester);
    return container;
  }

  testWidgets('opens filled in with what is stored', (tester) async {
    await openEditForm(tester);

    expect(find.text('차량 정보 수정'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, '차량 이름').first,
          )
          .controller
          ?.text,
      '아반떼',
    );
    // 주행거리는 여기서 고치지 않는다 — 홈의 수정과 갈래가 둘로 나뉘면 안 된다.
    expect(find.widgetWithText(TextFormField, '현재 주행거리 (km)'), findsNothing);
    await scrollTo(tester, find.textContaining('주행거리는 홈 화면에서 수정합니다'));
    expect(find.textContaining('주행거리는 홈 화면에서 수정합니다'), findsOneWidget);
  });

  testWidgets('saving renames the vehicle', (tester) async {
    final container = await openEditForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름').first,
      '아내 아반떼',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect((await readVehicles(container)).single.displayName, '아내 아반떼');
  });

  testWidgets('refuses an empty name', (tester) async {
    final container = await openEditForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름').first,
      '',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('차량 이름을 입력해 주세요'), findsOneWidget);
    expect((await readVehicles(container)).single.displayName, '아반떼');
  });

  testWidgets('rejects an out-of-range model year', (tester) async {
    await openEditForm(tester);

    await scrollTo(tester, find.widgetWithText(TextFormField, '연식'));
    await tester.enterText(find.widgetWithText(TextFormField, '연식'), '1800');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('연식을 다시 확인해 주세요'), findsOneWidget);
  });

  testWidgets('clearing an optional field clears it', (tester) async {
    final container = await openEditForm(tester);

    await scrollTo(tester, find.widgetWithText(TextFormField, '제조사'));
    await tester.enterText(find.widgetWithText(TextFormField, '제조사'), '');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect((await readVehicles(container)).single.manufacturer, isNull);
  });

  testWidgets('the body style survives an edit', (tester) async {
    final container = await openEditForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름').first,
      '이름만 바꿈',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect((await readVehicles(container)).single.bodyStyle, 'sedan');
  });

  testWidgets('the paint colour survives an edit', (tester) async {
    final container = await openEditForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름').first,
      '이름만 바꿈',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect((await readVehicles(container)).single.paintColor, 'blue');
  });

  testWidgets('repainting the car is saved', (tester) async {
    final container = await openEditForm(tester);

    await tester.tap(find.bySemanticsLabel('레드').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect((await readVehicles(container)).single.paintColor, 'red');
  });
}
