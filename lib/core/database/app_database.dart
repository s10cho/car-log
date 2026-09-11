import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'built_in_maintenance_types.dart';
import 'tables/app_preferences.dart';
import 'tables/maintenance_records.dart';
import 'tables/maintenance_types.dart';
import 'tables/receipt_assets.dart';
import 'tables/vehicle_maintenance_settings.dart';
import 'tables/vehicles.dart';

export 'built_in_maintenance_types.dart' show engineOilTypeCode;

part 'app_database.g.dart';

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
    ReceiptAssets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file for [name].
  AppDatabase.file(String name) : super(driftDatabase(name: name));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedBuiltInTypes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(vehicles);
        await m.createTable(maintenanceTypes);
        await m.createTable(vehicleMaintenanceSettings);
        await m.createTable(maintenanceRecords);
      }
      if (from < 3) {
        // v2 seeded 엔진오일 only; the rest of the catalogue arrives here.
        await seedBuiltInTypes();
      }
      if (from < 4) {
        await m.addColumn(
          vehicleMaintenanceSettings,
          vehicleMaintenanceSettings.notificationEnabled,
        );
      }
      if (from < 5) {
        await m.createTable(receiptAssets);
        await m.addColumn(
          maintenanceRecords,
          maintenanceRecords.receiptAssetId,
        );
      }
    },
    beforeOpen: (details) async {
      // Drift does not enable foreign keys by default; the cascade rules on
      // maintenance records depend on it.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Inserts any built-in maintenance type that is not already present.
  ///
  /// Matching is by [MaintenanceTypes.code], so re-running this never
  /// duplicates a row and never overwrites a name or interval the user edited.
  Future<void> seedBuiltInTypes() async {
    await batch((batch) {
      batch.insertAll(maintenanceTypes, [
        for (final type in builtInMaintenanceTypes)
          MaintenanceTypesCompanion.insert(
            code: Value(type.code),
            name: type.name,
            isBuiltIn: const Value(true),
            defaultDistanceInterval: Value(type.distanceInterval),
            defaultTimeIntervalMonths: Value(type.timeIntervalMonths),
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }
}
