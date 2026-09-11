import 'dart:convert';

import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/backup/data/backup_repository.dart';
import 'package:car_log/features/backup/domain/backup_document.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late BackupRepository backup;
  late VehicleRepository vehicles;
  late MaintenanceRepository maintenance;

  setUp(() {
    database = openTestDatabase();
    vehicles = openTestVehicleRepository(database);
    maintenance = openTestMaintenanceRepository(database);
    backup = BackupRepository(database, openTestReceiptStorage(database));
  });

  /// Two vehicles, a custom item, records and an interval override.
  Future<void> seed() async {
    final avante = await vehicles.create(
      displayName: '내 아반떼',
      currentMileage: 41000,
      manufacturer: '현대',
      model: '아반떼 CN7',
      modelYear: 2021,
      licensePlate: '12가3456',
      now: DateTime(2026, 1, 1),
    );
    final carnival = await vehicles.create(
      displayName: '카니발',
      currentMileage: 12000,
      now: DateTime(2026, 2, 1),
    );

    final engineOil = (await maintenance.engineOilType()).id;
    final coating = await maintenance.createCustomType(
      name: '하부 코팅',
      timeIntervalMonths: 24,
    );

    await maintenance.addRecord(
      vehicleId: avante,
      maintenanceTypeId: engineOil,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 33000,
      cost: 80000,
      shopName: '동네카센터',
      memo: '합성유',
    );
    await maintenance.addRecord(
      vehicleId: carnival,
      maintenanceTypeId: coating,
      maintenanceDate: DateTime(2026, 2, 10),
      mileage: 11000,
    );
    await maintenance.setInterval(
      vehicleId: avante,
      maintenanceTypeId: engineOil,
      interval: const MaintenanceInterval(distanceKm: 8000, months: 6),
    );
  }

  /// Exports, wipes, and restores through JSON — the path a real backup takes.
  Future<void> roundTrip() async {
    final document = await backup.buildBackup(appVersion: '1.0.0+1');
    final encoded = jsonEncode(document.toJson());

    await database.delete(database.maintenanceRecords).go();
    await database.delete(database.vehicleMaintenanceSettings).go();
    await database.delete(database.vehicles).go();
    await (database.delete(
      database.maintenanceTypes,
    )..where((t) => t.isBuiltIn.equals(false))).go();

    await backup.restore(parseBackupDocument(jsonDecode(encoded) as Object?));
  }

  group('a round trip', () {
    test('brings every vehicle back with its details', () async {
      await seed();
      await roundTrip();

      final all = await vehicles.watchAll().first;
      expect(all.map((v) => v.displayName), ['내 아반떼', '카니발']);
      final avante = all.first;
      expect(avante.manufacturer, '현대');
      expect(avante.model, '아반떼 CN7');
      expect(avante.modelYear, 2021);
      expect(avante.licensePlate, '12가3456');
      expect(avante.currentMileage, 41000);
    });

    test('brings every record back', () async {
      await seed();
      await roundTrip();

      final all = await vehicles.watchAll().first;
      final records = await maintenance.watchRecords(all.first.id).first;
      expect(records, hasLength(1));
      expect(records.single.mileage, 33000);
      expect(records.single.cost, 80000);
      expect(records.single.shopName, '동네카센터');
      expect(records.single.memo, '합성유');
      expect(records.single.maintenanceDate, DateTime(2026, 2, 1));
    });

    test('brings custom maintenance items back', () async {
      await seed();
      await roundTrip();

      final types = await maintenance.watchTypes().first;
      final coating = types.firstWhere((t) => t.name == '하부 코팅');
      expect(coating.isBuiltIn, isFalse);
      expect(coating.defaultTimeIntervalMonths, 24);
    });

    test('brings interval overrides back', () async {
      await seed();
      await roundTrip();

      final all = await vehicles.watchAll().first;
      final engineOil = (await maintenance.engineOilType()).id;
      final interval = await maintenance
          .watchInterval(vehicleId: all.first.id, maintenanceTypeId: engineOil)
          .first;

      expect(interval, const MaintenanceInterval(distanceKm: 8000, months: 6));
    });

    test('records still point at the right vehicle and item', () async {
      await seed();
      await roundTrip();

      final all = await vehicles.watchAll().first;
      final statuses = await maintenance
          .watchStatuses(vehicleId: all.last.id)
          .first;
      final coating = statuses.firstWhere((s) => s.typeName == '하부 코팅');
      expect(coating.hasRecord, isTrue);
      expect(coating.lastServiceMileage, 11000);
    });

    test('does not duplicate the built-in catalogue', () async {
      await seed();
      final before = (await maintenance.watchTypes().first).length;

      await roundTrip();

      expect((await maintenance.watchTypes().first), hasLength(before));
    });
  });

  group('what a backup carries', () {
    test('counts what it holds', () async {
      await seed();

      final document = await backup.buildBackup(appVersion: '1.0.0+1');

      expect(document.vehicleCount, 2);
      expect(document.recordCount, 2);
      expect(document.formatVersion, backupFormatVersion);
    });

    test('never carries an AI provider choice or consent', () async {
      await database
          .into(database.appPreferences)
          .insert(
            AppPreferencesCompanion.insert(
              key: 'ai_provider',
              value: 'openai',
              updatedAt: DateTime.now(),
            ),
          );
      await database
          .into(database.appPreferences)
          .insert(
            AppPreferencesCompanion.insert(
              key: 'ai_upload_consent',
              value: 'true',
              updatedAt: DateTime.now(),
            ),
          );

      final document = await backup.buildBackup(appVersion: '1.0.0+1');

      expect(document.preferences.containsKey('ai_provider'), isFalse);
      expect(document.preferences.containsKey('ai_upload_consent'), isFalse);
    });

    test('carries ordinary preferences', () async {
      await database
          .into(database.appPreferences)
          .insert(
            AppPreferencesCompanion.insert(
              key: 'reminders_lead_days',
              value: '14',
              updatedAt: DateTime.now(),
            ),
          );

      final document = await backup.buildBackup(appVersion: '1.0.0+1');

      expect(document.preferences['reminders_lead_days'], '14');
    });

    test('the encoded file contains no API key', () async {
      await seed();

      final encoded = jsonEncode(
        (await backup.buildBackup(appVersion: '1.0.0+1')).toJson(),
      );

      expect(encoded.toLowerCase(), isNot(contains('api_key')));
      expect(encoded.toLowerCase(), isNot(contains('apikey')));
      expect(encoded, isNot(contains('receiptAssetId')));
    });
  });

  group('restoring replaces rather than merges', () {
    test('data created after the export is gone', () async {
      await seed();
      final document = await backup.buildBackup(appVersion: '1.0.0+1');

      await vehicles.create(displayName: '나중에 산 차', currentMileage: 10);

      await backup.restore(document);

      final all = await vehicles.watchAll().first;
      expect(all.map((v) => v.displayName), ['내 아반떼', '카니발']);
    });

    test('restoring twice is the same as restoring once', () async {
      await seed();
      final document = await backup.buildBackup(appVersion: '1.0.0+1');

      await backup.restore(document);
      await backup.restore(document);

      expect(await vehicles.watchAll().first, hasLength(2));
    });
  });
}
