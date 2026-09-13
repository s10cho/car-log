import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  /// Two vehicles, each with its own 엔진오일 record, so that switching is
  /// visible in more than just the title.
  Future<({Widget app, ProviderContainer container})> twoVehicles() async {
    final built = buildTestApp();
    final vehicles = built.container.read(vehicleRepositoryProvider);
    final maintenance = built.container.read(maintenanceRepositoryProvider);
    final typeId = (await maintenance.engineOilType()).id;

    final avante = await vehicles.create(
      displayName: '내 아반떼',
      currentMileage: 32000,
      now: DateTime(2026, 1, 1),
    );
    final carnival = await vehicles.create(
      displayName: '카니발',
      currentMileage: 12000,
      now: DateTime(2026, 2, 1),
    );

    await maintenance.addRecord(
      vehicleId: avante,
      maintenanceTypeId: typeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );
    await maintenance.addRecord(
      vehicleId: carnival,
      maintenanceTypeId: typeId,
      maintenanceDate: DateTime(2026, 2, 10),
      mileage: 11000,
    );

    return built;
  }

  Future<void> openList(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
  }

  testWidgets('lists every vehicle and marks the current one', (tester) async {
    final (:app, :container) = await twoVehicles();
    await openList(tester, app);

    expect(find.text('내 아반떼'), findsOneWidget);
    expect(find.text('카니발'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('switching vehicles changes the home screen', (tester) async {
    final (:app, :container) = await twoVehicles();
    await tester.pumpWidget(app);
    await settle(tester);

    // 기본은 가장 먼저 등록한 차량.
    await settleAnimations(tester);
    expect(find.text('32,000 km'), findsOneWidget);
    expect(find.text('41,000 km'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
    await tester.tap(find.text('카니발'));
    await settleAnimations(tester);

    expect(find.text('12,000 km'), findsWidgets);
    expect(find.text('21,000 km'), findsOneWidget);
    expect(find.text('41,000 km'), findsNothing);
  });

  testWidgets('the 기록 tab follows the selected vehicle', (tester) async {
    final (:app, :container) = await twoVehicles();
    await tester.pumpWidget(app);
    await settle(tester);

    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
    await tester.tap(find.text('카니발'));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);

    expect(find.text('11,000 km'), findsOneWidget);
    expect(find.text('31,000 km'), findsNothing);
  });

  testWidgets('a newly added vehicle becomes the selected one', (tester) async {
    final (:app, :container) = await twoVehicles();
    await openList(tester, app);

    await tester.tap(find.widgetWithText(OutlinedButton, '차량 추가'));
    await settle(tester);
    // 위저드: 차종 → 색 → 이름 → 주행거리 → 완료
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '트럭');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '5000');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '차고에 넣기'));
    await settleAnimations(tester);

    // 목록으로 돌아온 뒤 홈까지 나간다. 주행거리는 굴러가며 표시되므로 기다린다.
    await tester.tap(find.byType(BackButton));
    await settleAnimations(tester);

    expect(find.text('트럭'), findsWidgets);
    expect(find.text('5,000 km'), findsWidgets);
  });

  testWidgets('editing a vehicle renames it everywhere', (tester) async {
    final (:app, :container) = await twoVehicles();
    await openList(tester, app);

    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await settle(tester);
    await tester.tap(find.text('정보 수정'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름'),
      '아내 아반떼',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('아내 아반떼'), findsOneWidget);
  });

  testWidgets('deleting the current vehicle falls back to the other one', (
    tester,
  ) async {
    final (:app, :container) = await twoVehicles();
    await openList(tester, app);

    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await settle(tester);
    await tester.tap(find.text('삭제'));
    await settle(tester);
    expect(find.textContaining('정비 기록과 교체주기 설정도 함께 삭제됩니다'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('내 아반떼'), findsNothing);
    expect(find.text('카니발'), findsOneWidget);
    await settleAnimations(tester);
    expect(find.text('12,000 km'), findsWidgets);
  });

  testWidgets('cancelling the delete dialog keeps the vehicle', (tester) async {
    final (:app, :container) = await twoVehicles();
    await openList(tester, app);

    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await settle(tester);
    await tester.tap(find.text('삭제'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await settle(tester);

    expect(find.text('내 아반떼'), findsOneWidget);
  });

  testWidgets('deleting the last vehicle returns to the empty state', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '유일차', currentMileage: 1000);

    await openList(tester, app);
    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await settle(tester);
    await tester.tap(find.text('삭제'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    expect(find.text('차고가 비어 있어요'), findsOneWidget);
  });
}
