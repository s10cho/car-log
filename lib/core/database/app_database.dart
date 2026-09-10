import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_preferences.dart';
import 'tables/maintenance_records.dart';
import 'tables/maintenance_types.dart';
import 'tables/vehicle_maintenance_settings.dart';
import 'tables/vehicles.dart';

part 'app_database.g.dart';

/// Stable code of the only maintenance type seeded in Slice 1.
const String engineOilTypeCode = 'engine_oil';

/// The single source of truth for all local data.
///
/// The UI renders from this database; remote integrations (Connected Car, AI)
/// write into it rather than being read directly by widgets.
@DriftDatabase(
  tables: [
    AppPreferences,
    Vehicles,
    MaintenanceTypes,
    VehicleMaintenanceSettings,
    MaintenanceRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file for [name].
  AppDatabase.file(String name) : super(driftDatabase(name: name));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedBuiltInTypes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(vehicles);
        await m.createTable(maintenanceTypes);
        await m.createTable(vehicleMaintenanceSettings);
        await m.createTable(maintenanceRecords);
        await _seedBuiltInTypes();
      }
    },
    beforeOpen: (details) async {
      // Drift does not enable foreign keys by default; the cascade rules on
      // maintenance records depend on it.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Inserts the maintenance types the app ships with.
  ///
  /// Only 엔진오일 for now: 10,000 km 또는 12개월 is the one interval the product
  /// spec states outright. The rest of the catalogue lands in Slice 3 rather
  /// than being invented here.
  Future<void> _seedBuiltInTypes() async {
    await into(maintenanceTypes).insert(
      MaintenanceTypesCompanion.insert(
        code: const Value(engineOilTypeCode),
        name: '엔진오일',
        isBuiltIn: const Value(true),
        defaultDistanceInterval: const Value(10000),
        defaultTimeIntervalMonths: const Value(12),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
