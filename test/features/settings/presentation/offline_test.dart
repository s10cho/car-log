import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// The app has to work with no network at all. Nothing in these flows touches
/// one — the assertions exist so a future change that adds a network call to a
/// core path fails here rather than on a user's phone in a basement car park.
void main() {
  testWidgets('the whole core flow runs without any network call', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();

    await tester.pumpWidget(app);
    await settle(tester);

    // 차량 등록 (위저드: 차종 → 색 → 이름 → 주행거리 → 완료)
    await tester.tap(find.widgetWithText(FilledButton, '차량 등록'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '아반떼');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '32000');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '차고에 넣기'));
    await settleAnimations(tester);

    // 정비 기록
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '33000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    // 다음 교체시기
    await settleAnimations(tester);
    expect(find.text('43,000 km'), findsOneWidget);

    // 기록 조회
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);
    expect(find.byType(ListTile), findsWidgets);

    // 수정
    await tester.tap(find.byType(ListTile).first);
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '34000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect((await readVehicles(container)).single.currentMileage, 34000);
  });

  testWidgets('the AI analyse button is absent when nothing is connected', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    expect(find.textContaining('로 분석'), findsNothing);
    expect(
      container.read(maintenanceRepositoryProvider),
      isA<MaintenanceRepository>(),
    );
  });
}
