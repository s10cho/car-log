import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_exception.dart';

/// Preference key holding the id of the vehicle the user is looking at.
const String selectedVehicleKey = 'selected_vehicle_id';

/// Reads and writes vehicles.
class VehicleRepository {
  const VehicleRepository(this._database);

  final AppDatabase _database;

  /// All vehicles, oldest first — the order they were added.
  Stream<List<Vehicle>> watchAll() {
    return (_database.select(
      _database.vehicles,
    )..orderBy([(v) => OrderingTerm.asc(v.createdAt)])).watch();
  }

  /// The vehicle the home screen shows: the one the user selected, or the
  /// oldest one when nothing is selected.
  ///
  /// The fallback is what makes deletion safe — when the selected vehicle is
  /// removed the selection simply stops matching and the next vehicle takes
  /// over, with no separate cleanup step.
  Stream<Vehicle?> watchCurrent() {
    return _database
        .customSelect(
          '''
          SELECT * FROM vehicles
          ORDER BY
            (id = (
              SELECT CAST(value AS INTEGER) FROM app_preferences
              WHERE key = ?1
            )) DESC,
            created_at ASC
          LIMIT 1
          ''',
          variables: [Variable.withString(selectedVehicleKey)],
          readsFrom: {_database.vehicles, _database.appPreferences},
        )
        .watchSingleOrNull()
        .map((row) => row == null ? null : _database.vehicles.map(row.data));
  }

  /// Remembers which vehicle the user is looking at.
  Future<void> select(int vehicleId) async {
    try {
      await _database
          .into(_database.appPreferences)
          .insertOnConflictUpdate(
            AppPreferencesCompanion.insert(
              key: selectedVehicleKey,
              value: '$vehicleId',
              updatedAt: DateTime.now(),
            ),
          );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to select vehicle $vehicleId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Vehicle?> findById(int id) {
    return (_database.select(
      _database.vehicles,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  /// Creates a vehicle and returns its id.
  Future<int> create({
    required String displayName,
    required int currentMileage,
    String? manufacturer,
    String? model,
    int? modelYear,
    String? licensePlate,
    String? vin,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    try {
      return await _database
          .into(_database.vehicles)
          .insert(
            VehiclesCompanion.insert(
              displayName: displayName,
              currentMileage: currentMileage,
              mileageUpdatedAt: timestamp,
              manufacturer: Value(manufacturer),
              model: Value(model),
              modelYear: Value(modelYear),
              licensePlate: Value(licensePlate),
              vin: Value(vin),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to create vehicle "$displayName"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Applies edits to an existing vehicle.
  ///
  /// Every optional field is written as given, so clearing a field in the form
  /// clears it in the database.
  Future<void> update({
    required int id,
    required String displayName,
    String? manufacturer,
    String? model,
    int? modelYear,
    String? licensePlate,
    String? vin,
    DateTime? now,
  }) async {
    try {
      await (_database.update(
        _database.vehicles,
      )..where((v) => v.id.equals(id))).write(
        VehiclesCompanion(
          displayName: Value(displayName),
          manufacturer: Value(manufacturer),
          model: Value(model),
          modelYear: Value(modelYear),
          licensePlate: Value(licensePlate),
          vin: Value(vin),
          updatedAt: Value(now ?? DateTime.now()),
        ),
      );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to update vehicle $id',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes a vehicle along with its maintenance records and interval
  /// overrides, which the schema cascades.
  Future<void> delete(int id) async {
    try {
      await (_database.delete(
        _database.vehicles,
      )..where((v) => v.id.equals(id))).go();
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to delete vehicle $id',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Records a new odometer reading.
  Future<void> updateMileage(
    int vehicleId,
    int mileage, {
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    try {
      await (_database.update(
        _database.vehicles,
      )..where((v) => v.id.equals(vehicleId))).write(
        VehiclesCompanion(
          currentMileage: Value(mileage),
          mileageUpdatedAt: Value(timestamp),
          updatedAt: Value(timestamp),
        ),
      );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to update mileage for vehicle $vehicleId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(ref.watch(appDatabaseProvider)),
);

/// The vehicle the home screen is showing, or null before the first one exists.
final currentVehicleProvider = StreamProvider<Vehicle?>(
  (ref) => ref.watch(vehicleRepositoryProvider).watchCurrent(),
);

/// Every vehicle, oldest first.
final vehicleListProvider = StreamProvider<List<Vehicle>>(
  (ref) => ref.watch(vehicleRepositoryProvider).watchAll(),
);
