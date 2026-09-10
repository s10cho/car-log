import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_exception.dart';

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

  /// The vehicle the home screen shows.
  ///
  /// Slice 1 has no vehicle switcher, so this is simply the first one added.
  /// Slice 2 replaces it with the user's selection.
  Stream<Vehicle?> watchCurrent() {
    return (_database.select(_database.vehicles)
          ..orderBy([(v) => OrderingTerm.asc(v.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
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
