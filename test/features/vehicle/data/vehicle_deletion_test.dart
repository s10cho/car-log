import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

/// Deleting a vehicle has to take its records and interval overrides with it.
/// If the cascade silently stopped working, rows would pile up invisibly and
/// reappear attached to a later vehicle that reused the id.
void main() {
  late AppDatabase database;
  late VehicleRepository vehicles;
  late MaintenanceRepository maintenance;
  late int vehicleId;
  late int otherId;
  late int typeId;

  setUp(() async {
    database = openTestDatabase();
    vehicles = openTestVehicleRepository(database);
    maintenance = openTestMaintenanceRepository(database);
    typeId = (await maintenance.engineOilType()).id;

    vehicleId = await vehicles.create(
      displayName: '아반떼',
      currentMileage: 32000,
      now: DateTime(2026, 1, 1),
    );
    otherId = await vehicles.create(
      displayName: '카니발',
      currentMileage: 12000,
      now: DateTime(2026, 2, 1),
    );

    for (final id in [vehicleId, otherId]) {
      await maintenance.addRecord(
        vehicleId: id,
        maintenanceTypeId: typeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 31000,
      );
      await maintenance.setInterval(
        vehicleId: id,
        maintenanceTypeId: typeId,
        interval: const MaintenanceInterval(distanceKm: 8000),
      );
    }
  });

  Future<int> countRecords(int id) async =>
      (await maintenance.watchRecords(id).first).length;

  Future<int> countSettings(int id) async {
    final rows = await (database.select(
      database.vehicleMaintenanceSettings,
    )..where((s) => s.vehicleId.equals(id))).get();
    return rows.length;
  }

  test('deleting a vehicle removes its maintenance records', () async {
    expect(await countRecords(vehicleId), 1);

    await vehicles.delete(vehicleId);

    expect(await countRecords(vehicleId), 0);
  });

  test('deleting a vehicle removes its interval overrides', () async {
    expect(await countSettings(vehicleId), 1);

    await vehicles.delete(vehicleId);

    expect(await countSettings(vehicleId), 0);
  });

  test('another vehicle keeps its records and overrides', () async {
    await vehicles.delete(vehicleId);

    expect(await countRecords(otherId), 1);
    expect(await countSettings(otherId), 1);
  });

  test('the maintenance type itself survives', () async {
    await vehicles.delete(vehicleId);
    await vehicles.delete(otherId);

    expect((await maintenance.engineOilType()).id, typeId);
  });
}
