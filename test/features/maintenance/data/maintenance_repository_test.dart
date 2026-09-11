import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late MaintenanceRepository repository;
  late VehicleRepository vehicles;
  late int vehicleId;
  late int engineOilTypeId;

  setUp(() async {
    database = openTestDatabase();
    repository = openTestMaintenanceRepository(database);
    vehicles = openTestVehicleRepository(database);
    vehicleId = await vehicles.create(
      displayName: '아반떼',
      currentMileage: 30000,
      now: DateTime(2026, 1, 1),
    );
    engineOilTypeId = (await repository.engineOilType()).id;
  });

  group('built-in types', () {
    test('엔진오일 is seeded with the documented interval', () async {
      final type = await repository.engineOilType();

      expect(type.name, '엔진오일');
      expect(type.isBuiltIn, isTrue);
      expect(type.defaultDistanceInterval, 10000);
      expect(type.defaultTimeIntervalMonths, 12);
    });
  });

  group('records', () {
    test('saves a record and reads it back', () async {
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 31000,
        cost: 80000,
        shopName: '동네카센터',
        memo: '합성유',
      );

      final records = await repository.watchRecords(vehicleId).first;
      expect(records, hasLength(1));
      expect(records.single.mileage, 31000);
      expect(records.single.cost, 80000);
      expect(records.single.shopName, '동네카센터');
      expect(records.single.memo, '합성유');
    });

    test('returns records most recent first', () async {
      for (final date in [
        DateTime(2026, 1, 5),
        DateTime(2026, 3, 5),
        DateTime(2026, 2, 5),
      ]) {
        await repository.addRecord(
          vehicleId: vehicleId,
          maintenanceTypeId: engineOilTypeId,
          maintenanceDate: date,
          mileage: 31000,
        );
      }

      final records = await repository.watchRecords(vehicleId).first;
      expect(records.map((r) => r.maintenanceDate), [
        DateTime(2026, 3, 5),
        DateTime(2026, 2, 5),
        DateTime(2026, 1, 5),
      ]);
    });

    test('a record with a higher reading moves the odometer forward', () async {
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 31500,
      );

      expect((await vehicles.findById(vehicleId))!.currentMileage, 31500);
    });

    test(
      'back-filling an older receipt does not move the odometer back',
      () async {
        await repository.addRecord(
          vehicleId: vehicleId,
          maintenanceTypeId: engineOilTypeId,
          maintenanceDate: DateTime(2025, 6, 1),
          mileage: 20000,
        );

        expect((await vehicles.findById(vehicleId))!.currentMileage, 30000);
      },
    );

    test('watchLatestRecord follows the newest service date', () async {
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 1, 5),
        mileage: 30500,
      );
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 3, 5),
        mileage: 32000,
      );

      final latest = await repository
          .watchLatestRecord(
            vehicleId: vehicleId,
            maintenanceTypeId: engineOilTypeId,
          )
          .first;
      expect(latest!.mileage, 32000);
    });

    test('records belong to one vehicle only', () async {
      final other = await vehicles.create(
        displayName: '다른차',
        currentMileage: 0,
      );
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 31000,
      );

      expect(await repository.watchRecords(other).first, isEmpty);
    });
  });

  group('intervals', () {
    test(
      'falls back to the type default when the vehicle has no override',
      () async {
        final interval = await repository
            .watchInterval(
              vehicleId: vehicleId,
              maintenanceTypeId: engineOilTypeId,
            )
            .first;

        expect(
          interval,
          const MaintenanceInterval(distanceKm: 10000, months: 12),
        );
      },
    );

    test('uses the vehicle override once one is set', () async {
      await repository.setInterval(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        interval: const MaintenanceInterval(distanceKm: 8000, months: 6),
      );

      final interval = await repository
          .watchInterval(
            vehicleId: vehicleId,
            maintenanceTypeId: engineOilTypeId,
          )
          .first;

      expect(interval, const MaintenanceInterval(distanceKm: 8000, months: 6));
    });

    test('an override applies to that vehicle alone', () async {
      final other = await vehicles.create(
        displayName: '다른차',
        currentMileage: 0,
      );
      await repository.setInterval(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        interval: const MaintenanceInterval(distanceKm: 5000, months: 6),
      );

      final interval = await repository
          .watchInterval(vehicleId: other, maintenanceTypeId: engineOilTypeId)
          .first;

      expect(
        interval,
        const MaintenanceInterval(distanceKm: 10000, months: 12),
      );
    });

    test('setting an interval twice overwrites rather than failing', () async {
      await repository.setInterval(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        interval: const MaintenanceInterval(distanceKm: 8000),
      );
      await repository.setInterval(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOilTypeId,
        interval: const MaintenanceInterval(distanceKm: 7000, months: 9),
      );

      final interval = await repository
          .watchInterval(
            vehicleId: vehicleId,
            maintenanceTypeId: engineOilTypeId,
          )
          .first;

      expect(interval, const MaintenanceInterval(distanceKm: 7000, months: 9));
    });
  });
}
