import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

/// The home screen's new job: say how the car is before the user reads
/// anything, and give them something to improve.
void main() {
  Future<int> addVehicle(
    ProviderContainer container, {
    int mileage = 40000,
    String style = 'sedan',
  }) => container
      .read(vehicleRepositoryProvider)
      .create(displayName: '내 아반떼', currentMileage: mileage, bodyStyle: style);

  Future<void> record(
    ProviderContainer container, {
    required int vehicleId,
    required String item,
    required DateTime date,
    required int mileage,
  }) async {
    final maintenance = container.read(maintenanceRepositoryProvider);
    final types = await readMaintenanceTypes(container);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: types.firstWhere((t) => t.name == item).id,
      maintenanceDate: date,
      mileage: mileage,
    );
  }

  group('the care score', () {
    testWidgets('is unrated until something is recorded', (tester) async {
      final (:app, :container) = buildTestApp();
      await addVehicle(container);

      await tester.pumpWidget(app);
      await settleAnimations(tester);

      expect(find.text('기록 없음'), findsOneWidget);
      expect(find.text('아주 좋아요'), findsNothing);
    });

    testWidgets('is full when everything is in order', (tester) async {
      final (:app, :container) = buildTestApp();
      final vehicleId = await addVehicle(container, mileage: 33000);
      await record(
        container,
        vehicleId: vehicleId,
        item: '엔진오일',
        date: DateTime.now().subtract(const Duration(days: 20)),
        mileage: 32000,
      );

      await tester.pumpWidget(app);
      await settleAnimations(tester);

      expect(find.text('100'), findsOneWidget);
      expect(find.text('아주 좋아요'), findsOneWidget);
    });

    testWidgets('drops and says so when an item is overdue', (tester) async {
      final (:app, :container) = buildTestApp();
      final vehicleId = await addVehicle(container, mileage: 60000);
      await record(
        container,
        vehicleId: vehicleId,
        item: '엔진오일',
        date: DateTime(2024, 1, 1),
        mileage: 32000,
      );

      await tester.pumpWidget(app);
      await settleAnimations(tester);

      expect(find.text('100'), findsNothing);
      expect(find.text('지남'), findsOneWidget);
    });
  });

  group('the odometer', () {
    testWidgets('counts up to the stored reading', (tester) async {
      final (:app, :container) = buildTestApp();
      await addVehicle(container, mileage: 47250);

      await tester.pumpWidget(app);
      // 중간에는 아직 최종값이 아니다.
      await settle(tester, frames: 3);
      expect(find.text('47,250 km'), findsNothing);

      await settleAnimations(tester);
      expect(find.text('47,250 km'), findsOneWidget);
    });
  });

  group('milestones', () {
    testWidgets('show locked badges as something to aim for', (tester) async {
      final (:app, :container) = buildTestApp();
      await addVehicle(container);

      await tester.pumpWidget(app);
      await settleAnimations(tester);
      await scrollTo(tester, find.text('첫 기록'));

      expect(find.text('첫 기록'), findsOneWidget);
      expect(find.text('기록 10건'), findsOneWidget);
    });

    testWidgets('unlock as the user records maintenance', (tester) async {
      final (:app, :container) = buildTestApp();
      final vehicleId = await addVehicle(container);
      await record(
        container,
        vehicleId: vehicleId,
        item: '엔진오일',
        date: DateTime.now(),
        mileage: 40000,
      );

      await tester.pumpWidget(app);
      await settleAnimations(tester);
      await scrollTo(tester, find.text('첫 기록'));

      // 달성한 배지가 먼저 온다.
      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where((text) => ['첫 기록', '기록 10건', '전부 정상'].contains(text))
          .toList();
      expect(labels.first, anyOf('첫 기록', '전부 정상'));
    });

    testWidgets('a distance mark shows the next one to reach', (tester) async {
      final (:app, :container) = buildTestApp();
      await addVehicle(container, mileage: 3000);

      await tester.pumpWidget(app);
      await settleAnimations(tester);
      await scrollTo(tester, find.text('1만 km'));

      expect(find.text('1만 km'), findsOneWidget);
      expect(find.text('5만 km'), findsNothing);
    });
  });

  group('the garage stage', () {
    testWidgets('is shown even with an empty garage', (tester) async {
      await tester.pumpWidget(buildTestApp().app);
      await settleAnimations(tester);

      expect(find.text('차고가 비어 있어요'), findsOneWidget);
      // 3D 가 안 되는 환경에서도 차 그림이 나온다.
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
