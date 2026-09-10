import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late VehicleRepository repository;

  setUp(() {
    database = openTestDatabase();
    repository = VehicleRepository(database);
  });

  test('creates a vehicle with the required fields', () async {
    final id = await repository.create(
      displayName: '내 아반떼',
      currentMileage: 32000,
      now: DateTime(2026, 3, 1),
    );

    final vehicle = await repository.findById(id);
    expect(vehicle!.displayName, '내 아반떼');
    expect(vehicle.currentMileage, 32000);
    expect(vehicle.mileageUpdatedAt, DateTime(2026, 3, 1));
  });

  test('keeps the optional fields it was given', () async {
    final id = await repository.create(
      displayName: '아반떼',
      currentMileage: 0,
      manufacturer: '현대',
      model: '아반떼 CN7',
      modelYear: 2021,
      licensePlate: '12가3456',
    );

    final vehicle = await repository.findById(id);
    expect(vehicle!.manufacturer, '현대');
    expect(vehicle.model, '아반떼 CN7');
    expect(vehicle.modelYear, 2021);
    expect(vehicle.licensePlate, '12가3456');
    expect(vehicle.vin, isNull);
  });

  test('watchCurrent emits null until a vehicle exists', () async {
    expect(await repository.watchCurrent().first, isNull);

    await repository.create(displayName: '아반떼', currentMileage: 0);

    expect((await repository.watchCurrent().first)!.displayName, '아반떼');
  });

  test('watchCurrent stays on the first vehicle added', () async {
    await repository.create(
      displayName: '첫차',
      currentMileage: 0,
      now: DateTime(2026, 1, 1),
    );
    await repository.create(
      displayName: '둘째차',
      currentMileage: 0,
      now: DateTime(2026, 2, 1),
    );

    expect((await repository.watchCurrent().first)!.displayName, '첫차');
  });

  test('watchAll returns vehicles oldest first', () async {
    await repository.create(
      displayName: '첫차',
      currentMileage: 0,
      now: DateTime(2026, 1, 1),
    );
    await repository.create(
      displayName: '둘째차',
      currentMileage: 0,
      now: DateTime(2026, 2, 1),
    );

    final all = await repository.watchAll().first;
    expect(all.map((v) => v.displayName), ['첫차', '둘째차']);
  });

  test('updateMileage moves the odometer and stamps the time', () async {
    final id = await repository.create(
      displayName: '아반떼',
      currentMileage: 32000,
      now: DateTime(2026, 1, 1),
    );

    await repository.updateMileage(id, 33500, now: DateTime(2026, 4, 1));

    final vehicle = await repository.findById(id);
    expect(vehicle!.currentMileage, 33500);
    expect(vehicle.mileageUpdatedAt, DateTime(2026, 4, 1));
  });

  test('findById returns null for an unknown id', () async {
    expect(await repository.findById(999), isNull);
  });
}
