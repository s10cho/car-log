import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  Future<void> openForm(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '차량 등록'));
    await settle(tester);
  }

  testWidgets('registers a vehicle and returns to the home screen', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await openForm(tester, app);

    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름'),
      '내 아반떼',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 주행거리 (km)'),
      '32000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    final vehicle = await container.read(vehicleRepositoryProvider).findById(1);
    expect(vehicle!.displayName, '내 아반떼');
    expect(vehicle.currentMileage, 32000);

    expect(find.text('내 아반떼'), findsOneWidget);
    expect(find.text('32,000 km'), findsOneWidget);
  });

  testWidgets('stores the optional details when they are filled in', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await openForm(tester, app);

    await tester.enterText(find.widgetWithText(TextFormField, '차량 이름'), '아반떼');
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 주행거리 (km)'),
      '32000',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '제조사'), '현대');
    await tester.enterText(find.widgetWithText(TextFormField, '모델'), '아반떼 CN7');
    await tester.enterText(find.widgetWithText(TextFormField, '연식'), '2021');
    await tester.enterText(
      find.widgetWithText(TextFormField, '차량번호'),
      '12가3456',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    final vehicle = await container.read(vehicleRepositoryProvider).findById(1);
    expect(vehicle!.manufacturer, '현대');
    expect(vehicle.model, '아반떼 CN7');
    expect(vehicle.modelYear, 2021);
    expect(vehicle.licensePlate, '12가3456');
  });

  testWidgets('refuses to save without a name or mileage', (tester) async {
    final (:app, :container) = buildTestApp();
    await openForm(tester, app);

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('차량 이름을 입력해 주세요'), findsOneWidget);
    expect(find.text('현재 주행거리를 입력해 주세요'), findsOneWidget);
    expect(await container.read(vehicleRepositoryProvider).findById(1), isNull);
  });

  testWidgets('rejects an implausible odometer reading', (tester) async {
    final app = buildTestApp().app;
    await openForm(tester, app);

    await tester.enterText(find.widgetWithText(TextFormField, '차량 이름'), '아반떼');
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 주행거리 (km)'),
      '9000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('주행거리를 다시 확인해 주세요'), findsOneWidget);
  });

  testWidgets('rejects an out-of-range model year', (tester) async {
    final app = buildTestApp().app;
    await openForm(tester, app);

    await tester.enterText(find.widgetWithText(TextFormField, '차량 이름'), '아반떼');
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 주행거리 (km)'),
      '1000',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '연식'), '1800');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('연식을 다시 확인해 주세요'), findsOneWidget);
  });
}
