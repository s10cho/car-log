import 'dart:io';

import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/core/database/built_in_maintenance_types.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Every shipped schema version has to open on a device that was already
/// running an older one. A migration only ever exercised on a fresh database is
/// untested exactly where it matters — on the phone of someone with data.
///
/// These build a real file with an old schema, then let the current code open
/// it, which is the only way `onUpgrade` actually runs.
void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('car_log_migration');
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
  });

  /// Writes a v1 database: app_preferences only, which is all Slice 0 shipped.
  File writeV1Database({Map<String, String> preferences = const {}}) {
    final file = File(p.join(directory.path, 'v1.sqlite'));
    final raw = sqlite3.open(file.path);
    raw
      ..execute('''
        CREATE TABLE app_preferences (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''')
      ..execute('PRAGMA user_version = 1');
    for (final entry in preferences.entries) {
      raw.execute('INSERT INTO app_preferences VALUES (?, ?, 0)', [
        entry.key,
        entry.value,
      ]);
    }
    raw.close();
    return file;
  }

  AppDatabase open(File file) {
    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    return database;
  }

  test('a v1 database gains every later table', () async {
    final database = open(writeV1Database());

    // Each of these would throw "no such table" if a migration step was missed.
    expect(await database.select(database.vehicles).get(), isEmpty);
    expect(await database.select(database.maintenanceRecords).get(), isEmpty);
    expect(await database.select(database.receiptAssets).get(), isEmpty);
    expect(
      await database.select(database.vehicleMaintenanceSettings).get(),
      isEmpty,
    );
  });

  test('a v1 database gains the built-in catalogue', () async {
    final database = open(writeV1Database());

    final types = await database.select(database.maintenanceTypes).get();

    expect(types, hasLength(builtInMaintenanceTypes.length));
    expect(types.map((t) => t.code), contains(engineOilTypeCode));
  });

  test('preferences written before the upgrade survive it', () async {
    final database = open(
      writeV1Database(preferences: {'reminders_lead_days': '14'}),
    );

    final rows = await database.select(database.appPreferences).get();

    expect(rows.single.key, 'reminders_lead_days');
    expect(rows.single.value, '14');
  });

  test('the upgraded database is stamped with the current version', () async {
    final database = open(writeV1Database());
    await database.customSelect('SELECT 1').get();

    final row = await database.customSelect('PRAGMA user_version').getSingle();

    expect(row.data.values.first, database.schemaVersion);
  });

  test('reopening an upgraded database changes nothing further', () async {
    final file = writeV1Database();
    final first = open(file);
    await first.select(first.maintenanceTypes).get();
    await first.close();

    final second = open(file);
    final types = await second.select(second.maintenanceTypes).get();

    expect(types, hasLength(builtInMaintenanceTypes.length));
  });

  test('a fresh database starts at the current version', () async {
    final database = open(File(p.join(directory.path, 'fresh.sqlite')));
    await database.customSelect('SELECT 1').get();

    final row = await database.customSelect('PRAGMA user_version').getSingle();

    expect(row.data.values.first, database.schemaVersion);
  });

  test('foreign keys are enabled, so deletes cascade', () async {
    final database = open(File(p.join(directory.path, 'fk.sqlite')));

    final row = await database.customSelect('PRAGMA foreign_keys').getSingle();

    expect(row.data.values.first, 1);
  });

  /// Writes the schema as it stood at v2: the domain tables exist, but without
  /// `notification_enabled` or `receipt_asset_id`, and only 엔진오일 is seeded.
  File writeV2Database() {
    final file = File(p.join(directory.path, 'v2.sqlite'));
    final raw = sqlite3.open(file.path);
    raw
      ..execute(
        'CREATE TABLE app_preferences ('
        'key TEXT NOT NULL PRIMARY KEY, '
        'value TEXT NOT NULL, '
        'updated_at INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE vehicles ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'display_name TEXT NOT NULL, '
        'manufacturer TEXT NULL, '
        'model TEXT NULL, '
        'model_year INTEGER NULL, '
        'vin TEXT NULL, '
        'license_plate TEXT NULL, '
        'current_mileage INTEGER NOT NULL, '
        'mileage_updated_at INTEGER NOT NULL, '
        'created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL)',
      )
      ..execute(
        'CREATE TABLE maintenance_types ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'code TEXT NULL UNIQUE, '
        'name TEXT NOT NULL, '
        'is_built_in INTEGER NOT NULL DEFAULT 0, '
        'default_distance_interval INTEGER NULL, '
        'default_time_interval_months INTEGER NULL)',
      )
      ..execute(
        'CREATE TABLE vehicle_maintenance_settings ('
        'vehicle_id INTEGER NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE, '
        'maintenance_type_id INTEGER NOT NULL '
        'REFERENCES maintenance_types (id) ON DELETE CASCADE, '
        'distance_interval INTEGER NULL, '
        'time_interval_months INTEGER NULL, '
        'PRIMARY KEY (vehicle_id, maintenance_type_id))',
      )
      ..execute(
        'CREATE TABLE maintenance_records ('
        'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'vehicle_id INTEGER NOT NULL REFERENCES vehicles (id) ON DELETE CASCADE, '
        'maintenance_type_id INTEGER NOT NULL '
        'REFERENCES maintenance_types (id) ON DELETE RESTRICT, '
        'maintenance_date INTEGER NOT NULL, '
        'mileage INTEGER NOT NULL, '
        'cost INTEGER NULL, '
        'shop_name TEXT NULL, '
        'memo TEXT NULL, '
        'created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL)',
      )
      ..execute(
        'INSERT INTO maintenance_types (code, name, is_built_in, '
        'default_distance_interval, default_time_interval_months) '
        "VALUES ('engine_oil', '엔진오일', 1, 10000, 12)",
      )
      ..execute(
        'INSERT INTO vehicles (display_name, current_mileage, '
        'mileage_updated_at, created_at, updated_at) '
        "VALUES ('내 아반떼', 32000, 0, 0, 0)",
      )
      ..execute(
        'INSERT INTO maintenance_records (vehicle_id, maintenance_type_id, '
        'maintenance_date, mileage, created_at, updated_at) '
        'VALUES (1, 1, 0, 31000, 0, 0)',
      )
      ..execute('PRAGMA user_version = 2');
    raw.close();
    return file;
  }

  group('upgrading from v2', () {
    test('keeps the vehicle and the record', () async {
      final database = open(writeV2Database());

      final vehicles = await database.select(database.vehicles).get();
      final records = await database.select(database.maintenanceRecords).get();

      expect(vehicles.single.displayName, '내 아반떼');
      expect(records.single.mileage, 31000);
    });

    test('adds the rest of the catalogue without duplicating 엔진오일', () async {
      final database = open(writeV2Database());

      final types = await database.select(database.maintenanceTypes).get();

      expect(types, hasLength(builtInMaintenanceTypes.length));
      expect(types.where((t) => t.code == engineOilTypeCode), hasLength(1));
    });

    test('adds the columns later versions introduced', () async {
      final database = open(writeV2Database());

      // Each would throw "no such column" if an ALTER step was skipped.
      await database
          .customSelect(
            'SELECT notification_enabled FROM vehicle_maintenance_settings',
          )
          .get();
      await database
          .customSelect('SELECT receipt_asset_id FROM maintenance_records')
          .get();
      await database
          .customSelect('SELECT body_style, paint_color FROM vehicles')
          .get();
    });

    test('a car registered before colours keeps none', () async {
      final database = open(writeV2Database());

      final vehicle = (await database.select(database.vehicles).get()).single;

      expect(vehicle.bodyStyle, isNull);
      expect(vehicle.paintColor, isNull);
    });

    test('the record still has no receipt attached', () async {
      final database = open(writeV2Database());

      final records = await database.select(database.maintenanceRecords).get();

      expect(records.single.receiptAssetId, isNull);
    });
  });
}
