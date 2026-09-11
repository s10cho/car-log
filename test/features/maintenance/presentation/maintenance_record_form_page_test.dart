import 'package:car_log/features/maintenance/presentation/maintenance_record_form_page.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  // These assert through the UI rather than reading the database back: awaiting
  // a Drift *stream* inside testWidgets never returns, because the test binding
  // holds the clock that the stream's timers wait on.
  Future<void> openFormWithVehicle(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
  }

  testWidgets('saves a record and shows it on the home screen', (tester) async {
    await openFormWithVehicle(tester);

    expect(find.text('정비 기록'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '33000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '비용 (원)'),
      '80000',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '정비소'), '동네카센터');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.byType(MaintenanceRecordFormPage), findsNothing);
    expect(find.text('33,000 km · 80,000원 · 동네카센터'), findsOneWidget);
    expect(find.text('43,000 km'), findsOneWidget);
  });

  testWidgets('a record moves the odometer forward', (tester) async {
    await openFormWithVehicle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '35000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('35,000 km'), findsWidgets);
  });

  testWidgets('refuses to save without a mileage', (tester) async {
    await openFormWithVehicle(tester);

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('주행거리를 입력해 주세요'), findsOneWidget);
    expect(find.byType(MaintenanceRecordFormPage), findsOneWidget);
  });

  testWidgets('shows the current odometer as a hint', (tester) async {
    await openFormWithVehicle(tester);

    expect(find.text('현재 32,000 km'), findsOneWidget);
  });
}
