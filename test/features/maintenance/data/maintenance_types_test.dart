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

  setUp(() async {
    database = openTestDatabase();
    repository = MaintenanceRepository(database);
    vehicles = VehicleRepository(database);
    vehicleId = await vehicles.create(
      displayName: '아반떼',
      currentMileage: 40000,
      now: DateTime(2026, 1, 1),
    );
  });

  Future<int> typeIdFor(String name) async {
    final types = await repository.watchTypes().first;
    return types.firstWhere((type) => type.name == name).id;
  }

  group('custom types', () {
    test('appear after the built-in ones', () async {
      await repository.createCustomType(name: '하부 코팅', timeIntervalMonths: 24);

      final types = await repository.watchTypes().first;
      expect(types.last.name, '하부 코팅');
      expect(types.last.isBuiltIn, isFalse);
    });

    test('can be recorded against like any other item', () async {
      final id = await repository.createCustomType(
        name: '하부 코팅',
        timeIntervalMonths: 24,
      );

      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: id,
        maintenanceDate: DateTime(2026, 1, 10),
        mileage: 39000,
      );

      final statuses = await repository
          .watchStatuses(
            vehicleId: vehicleId,
            clock: () => DateTime(2026, 3, 1),
          )
          .first;
      final coating = statuses.firstWhere((s) => s.typeId == id);
      expect(coating.hasRecord, isTrue);
      expect(coating.due!.dueDate, DateTime(2028, 1, 10));
      expect(coating.due!.dueMileage, isNull);
    });

    test('can be renamed and re-timed', () async {
      final id = await repository.createCustomType(
        name: '하부 코팅',
        timeIntervalMonths: 24,
      );

      await repository.updateType(
        id: id,
        name: '언더코팅',
        distanceInterval: 30000,
        timeIntervalMonths: 36,
      );

      final types = await repository.watchTypes().first;
      final updated = types.firstWhere((type) => type.id == id);
      expect(updated.name, '언더코팅');
      expect(updated.defaultDistanceInterval, 30000);
      expect(updated.defaultTimeIntervalMonths, 36);
    });

    test('can be deleted when nothing references them', () async {
      final id = await repository.createCustomType(name: '하부 코팅');

      expect(await repository.recordCountForType(id), 0);
      await repository.deleteType(id);

      final types = await repository.watchTypes().first;
      expect(types.map((t) => t.id), isNot(contains(id)));
    });

    test('report how many records reference them', () async {
      final id = await repository.createCustomType(name: '하부 코팅');
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: id,
        maintenanceDate: DateTime(2026, 1, 10),
        mileage: 39000,
      );

      expect(await repository.recordCountForType(id), 1);
    });

    test('a built-in type is never deleted', () async {
      final engineOil = await typeIdFor('엔진오일');

      await repository.deleteType(engineOil);

      final types = await repository.watchTypes().first;
      expect(types.map((t) => t.id), contains(engineOil));
    });
  });

  group('editing a built-in type', () {
    test(
      'changes the recommendation for every vehicle without an override',
      () async {
        final wiper = await typeIdFor('와이퍼');

        await repository.updateType(
          id: wiper,
          name: '와이퍼 블레이드',
          timeIntervalMonths: 6,
        );

        final interval = await repository
            .watchInterval(vehicleId: vehicleId, maintenanceTypeId: wiper)
            .first;
        expect(interval, const MaintenanceInterval(months: 6));
      },
    );

    test('does not override a vehicle that set its own interval', () async {
      final wiper = await typeIdFor('와이퍼');
      await repository.setInterval(
        vehicleId: vehicleId,
        maintenanceTypeId: wiper,
        interval: const MaintenanceInterval(months: 18),
      );

      await repository.updateType(
        id: wiper,
        name: '와이퍼',
        timeIntervalMonths: 6,
      );

      final interval = await repository
          .watchInterval(vehicleId: vehicleId, maintenanceTypeId: wiper)
          .first;
      expect(interval, const MaintenanceInterval(months: 18));
    });
  });

  group('ordering by urgency', () {
    test('puts overdue first, then 임박, then 여유', () async {
      final engineOil = await typeIdFor('엔진오일');
      final wiper = await typeIdFor('와이퍼');
      final coolant = await typeIdFor('냉각수');
      const today = 2026;

      // 엔진오일: 40,000 현재 / 기준 10,000 → 이미 지남.
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOil,
        maintenanceDate: DateTime(today, 1, 1),
        mileage: 25000,
      );
      // 와이퍼: 12개월 기준, 11개월 전 → 임박.
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: wiper,
        maintenanceDate: DateTime(today - 1, 4, 15),
        mileage: 30000,
      );
      // 냉각수: 100,000 km / 48개월 → 여유.
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: coolant,
        maintenanceDate: DateTime(today, 2, 1),
        mileage: 39000,
      );

      final statuses =
          (await repository
                  .watchStatuses(
                    vehicleId: vehicleId,
                    clock: () => DateTime(2026, 3, 20),
                  )
                  .first)
              .where((s) => s.hasRecord)
              .toList()
            ..sort(compareByUrgency);

      expect(statuses.map((s) => s.typeName), ['엔진오일', '와이퍼', '냉각수']);
    });

    test('items with no due point sort last', () async {
      final brakePad = await typeIdFor('브레이크 패드');
      await repository.updateType(id: brakePad, name: '브레이크 패드');
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: brakePad,
        maintenanceDate: DateTime(2026, 1, 1),
        mileage: 39000,
      );
      final engineOil = await typeIdFor('엔진오일');
      await repository.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOil,
        maintenanceDate: DateTime(2026, 1, 1),
        mileage: 39000,
      );

      final statuses =
          (await repository.watchStatuses(vehicleId: vehicleId).first)
              .where((s) => s.hasRecord)
              .toList()
            ..sort(compareByUrgency);

      expect(statuses.last.typeName, '브레이크 패드');
      expect(statuses.last.due, isNull);
    });
  });
}
