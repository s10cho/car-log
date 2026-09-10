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

  group('selection', () {
    test('defaults to the oldest vehicle when nothing is selected', () async {
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

    test('follows the selected vehicle', () async {
      await repository.create(
        displayName: '첫차',
        currentMileage: 0,
        now: DateTime(2026, 1, 1),
      );
      final second = await repository.create(
        displayName: '둘째차',
        currentMileage: 0,
        now: DateTime(2026, 2, 1),
      );

      await repository.select(second);

      expect((await repository.watchCurrent().first)!.displayName, '둘째차');
    });

    test(
      'falls back to another vehicle when the selected one is deleted',
      () async {
        final first = await repository.create(
          displayName: '첫차',
          currentMileage: 0,
          now: DateTime(2026, 1, 1),
        );
        final second = await repository.create(
          displayName: '둘째차',
          currentMileage: 0,
          now: DateTime(2026, 2, 1),
        );
        await repository.select(second);

        await repository.delete(second);

        expect((await repository.watchCurrent().first)!.id, first);
      },
    );

    test('selecting twice keeps the latest choice', () async {
      final first = await repository.create(
        displayName: '첫차',
        currentMileage: 0,
        now: DateTime(2026, 1, 1),
      );
      final second = await repository.create(
        displayName: '둘째차',
        currentMileage: 0,
        now: DateTime(2026, 2, 1),
      );

      await repository.select(second);
      await repository.select(first);

      expect((await repository.watchCurrent().first)!.id, first);
    });

    test('emits null once the last vehicle is deleted', () async {
      final only = await repository.create(
        displayName: '유일차',
        currentMileage: 0,
      );
      await repository.select(only);

      await repository.delete(only);

      expect(await repository.watchCurrent().first, isNull);
    });

    test('re-emits when the selection changes', () async {
      await repository.create(
        displayName: '첫차',
        currentMileage: 0,
        now: DateTime(2026, 1, 1),
      );
      final second = await repository.create(
        displayName: '둘째차',
        currentMileage: 0,
        now: DateTime(2026, 2, 1),
      );

      final emitted = <String?>[];
      final subscription = repository.watchCurrent().listen(
        (vehicle) => emitted.add(vehicle?.displayName),
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await repository.select(second);
      await pumpEventQueue();

      expect(emitted, ['첫차', '둘째차']);
    });
  });

  group('editing', () {
    test('update changes the fields it is given', () async {
      final id = await repository.create(
        displayName: '아반떼',
        currentMileage: 32000,
        manufacturer: '현대',
      );

      await repository.update(
        id: id,
        displayName: '아내 아반떼',
        manufacturer: '현대',
        model: '아반떼 CN7',
        modelYear: 2021,
      );

      final vehicle = await repository.findById(id);
      expect(vehicle!.displayName, '아내 아반떼');
      expect(vehicle.model, '아반떼 CN7');
      expect(vehicle.modelYear, 2021);
    });

    test('update clears an optional field that is left out', () async {
      final id = await repository.create(
        displayName: '아반떼',
        currentMileage: 0,
        manufacturer: '현대',
      );

      await repository.update(id: id, displayName: '아반떼');

      expect((await repository.findById(id))!.manufacturer, isNull);
    });

    test('update leaves the odometer alone', () async {
      final id = await repository.create(
        displayName: '아반떼',
        currentMileage: 32000,
      );

      await repository.update(id: id, displayName: '아반떼 II');

      expect((await repository.findById(id))!.currentMileage, 32000);
    });

    test('delete removes the vehicle', () async {
      final id = await repository.create(displayName: '아반떼', currentMileage: 0);

      await repository.delete(id);

      expect(await repository.findById(id), isNull);
    });
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
