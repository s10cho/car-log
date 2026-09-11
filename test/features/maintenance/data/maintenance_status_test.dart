import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/maintenance/domain/maintenance_status.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late MaintenanceRepository repository;
  late VehicleRepository vehicles;
  late int vehicleId;
  late int engineOilTypeId;

  DateTime today = DateTime(2026, 3, 1);

  /// 엔진오일 한 항목만 골라 본다. 나머지 기본 항목은 같은 쿼리로 함께 온다.
  Stream<MaintenanceStatus?> status([int? id]) => repository
      .watchStatuses(vehicleId: id ?? vehicleId, clock: () => today)
      .map((all) => all.where((s) => s.typeId == engineOilTypeId).firstOrNull);

  setUp(() async {
    today = DateTime(2026, 3, 1);
    database = openTestDatabase();
    repository = MaintenanceRepository(database);
    vehicles = VehicleRepository(database);
    vehicleId = await vehicles.create(
      displayName: '아반떼',
      currentMileage: 30000,
      now: DateTime(2026, 1, 1),
    );
    engineOilTypeId = (await repository.engineOilType()).id;
  });

  test('reports the type and interval before any record exists', () async {
    final result = (await status().first)!;

    expect(result.typeName, '엔진오일');
    expect(
      result.interval,
      const MaintenanceInterval(distanceKm: 10000, months: 12),
    );
    expect(result.hasRecord, isFalse);
    expect(result.due, isNull);
  });

  test('returns nothing for a vehicle that does not exist', () async {
    expect(await status(999).first, isNull);
    expect(await repository.watchStatuses(vehicleId: 999).first, isEmpty);
  });

  test('covers every built-in type, recorded or not', () async {
    final all = await repository.watchStatuses(vehicleId: vehicleId).first;

    expect(all.map((s) => s.typeName), contains('엔진오일'));
    expect(all.map((s) => s.typeName), contains('와이퍼'));
    expect(all.every((s) => s.hasRecord), isFalse);
  });

  test('projects the due point from the last record', () async {
    await repository.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );

    final result = (await status().first)!;

    expect(result.hasRecord, isTrue);
    expect(result.lastServiceMileage, 31000);
    expect(result.due!.dueMileage, 41000);
    expect(result.due!.dueDate, DateTime(2027, 2, 1));
    expect(result.due!.urgency, MaintenanceUrgency.ok);
  });

  test(
    'measures the remaining distance against the current odometer',
    () async {
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 31000,
      );
      await vehicles.updateMileage(vehicleId, 40500);

      final result = (await status().first)!;

      expect(result.due!.remainingDistanceKm, 500);
      expect(result.due!.urgency, MaintenanceUrgency.dueSoon);
    },
  );

  test('goes overdue once the odometer passes the due mileage', () async {
    await repository.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );
    await vehicles.updateMileage(vehicleId, 41500);

    expect((await status().first)!.due!.urgency, MaintenanceUrgency.overdue);
  });

  test(
    'projects from the newest record, not the most recently added',
    () async {
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 31000,
      );
      // 예전 영수증을 뒤늦게 입력.
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2025, 8, 1),
        mileage: 21000,
      );

      final result = (await status().first)!;

      expect(result.lastServiceDate, DateTime(2026, 2, 1));
      expect(result.due!.dueMileage, 41000);
    },
  );

  test('honours a vehicle interval override', () async {
    await repository.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );
    await repository.setInterval(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      interval: const MaintenanceInterval(distanceKm: 5000, months: 6),
    );

    final result = (await status().first)!;

    expect(
      result.interval,
      const MaintenanceInterval(distanceKm: 5000, months: 6),
    );
    expect(result.due!.dueMileage, 36000);
    expect(result.due!.dueDate, DateTime(2026, 8, 1));
  });

  test('ignores records belonging to another vehicle', () async {
    final other = await vehicles.create(displayName: '다른차', currentMileage: 0);
    await repository.addRecord(
      vehicleId: other,
      maintenanceTypeId: engineOilTypeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );

    expect((await status().first)!.hasRecord, isFalse);
  });

  test('re-emits when a record is added', () async {
    final emitted = <MaintenanceStatus?>[];
    final subscription = status().listen(emitted.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emitted.last!.hasRecord, isFalse);

    await repository.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );
    await pumpEventQueue();

    expect(emitted.last!.hasRecord, isTrue);
    expect(emitted.last!.due!.dueMileage, 41000);
  });

  test('re-emits when the interval changes', () async {
    await repository.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 31000,
    );

    final emitted = <MaintenanceStatus?>[];
    final subscription = status().listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.setInterval(
      vehicleId: vehicleId,
      maintenanceTypeId: engineOilTypeId,
      interval: const MaintenanceInterval(distanceKm: 5000),
    );
    await pumpEventQueue();

    expect(emitted.last!.due!.dueMileage, 36000);
  });
}
