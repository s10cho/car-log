import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  testWidgets('shows the first-use empty state when no vehicle exists', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp().app);
    await settle(tester);

    expect(find.text('아직 등록된 차량이 없습니다'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '차량 등록'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('shows the vehicle name and odometer once one exists', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '내 아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);

    expect(find.text('내 아반떼'), findsOneWidget);
    expect(find.text('32,000 km'), findsOneWidget);
    expect(find.text('아직 등록된 차량이 없습니다'), findsNothing);
  });

  testWidgets('lists nothing to track until something is recorded', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);

    // 기본 항목 10개를 모두 늘어놓지 않는다.
    expect(find.text('엔진오일'), findsNothing);
    expect(find.text('와이퍼'), findsNothing);
    expect(find.text('정비를 기록하면 다음 교체 시기를 여기에서 확인할 수 있습니다.'), findsOneWidget);
  });

  testWidgets('shows the next due mileage and date after a record', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );

    await tester.pumpWidget(app);
    await settle(tester);

    expect(find.text('41,000 km'), findsOneWidget);
    expect(find.text('2027.02.01'), findsOneWidget);
    expect(find.text('마지막 교체 2026.02.01 · 31,000 km'), findsOneWidget);
    expect(find.text('교체주기 10,000 km 또는 12개월'), findsOneWidget);
  });

  testWidgets('marks an overdue item', (tester) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 20000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime(2020, 1, 1),
      mileage: 19000,
    );

    await tester.pumpWidget(app);
    await settle(tester);

    expect(find.text('지남'), findsOneWidget);
  });

  testWidgets('lists recent records', (tester) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
      cost: 80000,
      shopName: '동네카센터',
    );

    await tester.pumpWidget(app);
    await settle(tester);

    expect(find.text('31,000 km · 80,000원 · 동네카센터'), findsOneWidget);
  });

  testWidgets('updating the odometer changes the remaining distance', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );

    await tester.pumpWidget(app);
    await settle(tester);
    expect(find.text('9,000 km 남음'), findsOneWidget);

    await tester.tap(find.text('수정'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, '40500');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('500 km 남음'), findsOneWidget);
    expect(find.text('임박'), findsOneWidget);
  });

  testWidgets('changing the interval moves the due point', (tester) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );
    await maintenance.setInterval(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      interval: const MaintenanceInterval(distanceKm: 5000, months: 6),
    );

    await tester.pumpWidget(app);
    await settle(tester);

    expect(find.text('36,000 km'), findsOneWidget);
    expect(find.text('교체주기 5,000 km 또는 6개월'), findsOneWidget);
  });

  testWidgets('lists several tracked items, most pressing first', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 40000);
    final types = await readMaintenanceTypes(container);
    int idOf(String name) => types.firstWhere((t) => t.name == name).id;

    // 엔진오일: 25,000 km 에 교체, 기준 10,000 → 이미 지남.
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: idOf('엔진오일'),
      maintenanceDate: DateTime(2026, 1, 1),
      mileage: 25000,
    );
    // 냉각수: 100,000 km 기준 → 여유.
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: idOf('냉각수'),
      maintenanceDate: DateTime(2026, 1, 1),
      mileage: 39000,
    );

    await tester.pumpWidget(app);
    await settle(tester);

    expect(find.text('엔진오일'), findsOneWidget);
    expect(find.text('냉각수'), findsOneWidget);
    // 기록하지 않은 항목은 홈에 나오지 않는다.
    expect(find.text('와이퍼'), findsNothing);

    final cards = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(cards.indexOf('엔진오일'), lessThan(cards.indexOf('냉각수')));
    expect(find.text('지남'), findsOneWidget);
    expect(find.text('여유'), findsOneWidget);
  });

  testWidgets('recording a different item adds it to the home list', (
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

    await tester.tap(find.text('엔진오일'));
    await settle(tester);
    await tester.tap(find.text('와이퍼').last);
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '32000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('와이퍼'), findsWidgets);
    expect(find.text('엔진오일'), findsNothing);
  });
}
