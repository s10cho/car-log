import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../vehicle/data/vehicle_repository.dart';
import '../domain/maintenance_schedule.dart';
import '../domain/maintenance_status.dart';

/// Reads and writes maintenance records, types and per-vehicle intervals.
class MaintenanceRepository {
  const MaintenanceRepository(this._database);

  final AppDatabase _database;

  /// The built-in 엔진오일 type, seeded when the database is created.
  Future<MaintenanceType> engineOilType() async {
    final type = await (_database.select(
      _database.maintenanceTypes,
    )..where((t) => t.code.equals(engineOilTypeCode))).getSingleOrNull();

    if (type == null) {
      throw const LocalDatabaseException(
        'Built-in maintenance type "$engineOilTypeCode" is missing',
      );
    }
    return type;
  }

  /// Every record for a vehicle, most recent first.
  Stream<List<MaintenanceRecord>> watchRecords(int vehicleId) {
    return (_database.select(_database.maintenanceRecords)
          ..where((r) => r.vehicleId.equals(vehicleId))
          ..orderBy([
            (r) => OrderingTerm.desc(r.maintenanceDate),
            (r) => OrderingTerm.desc(r.id),
          ]))
        .watch();
  }

  /// The most recent record of one type, which is what the next due point is
  /// projected from.
  Stream<MaintenanceRecord?> watchLatestRecord({
    required int vehicleId,
    required int maintenanceTypeId,
  }) {
    return (_database.select(_database.maintenanceRecords)
          ..where(
            (r) =>
                r.vehicleId.equals(vehicleId) &
                r.maintenanceTypeId.equals(maintenanceTypeId),
          )
          ..orderBy([
            (r) => OrderingTerm.desc(r.maintenanceDate),
            (r) => OrderingTerm.desc(r.id),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Saves a record.
  ///
  /// A reading taken during service is newer than whatever the vehicle carried
  /// before, so it moves the odometer forward — but never backward, which would
  /// happen when back-filling an old receipt.
  Future<int> addRecord({
    required int vehicleId,
    required int maintenanceTypeId,
    required DateTime maintenanceDate,
    required int mileage,
    int? cost,
    String? shopName,
    String? memo,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    try {
      return await _database.transaction(() async {
        final id = await _database
            .into(_database.maintenanceRecords)
            .insert(
              MaintenanceRecordsCompanion.insert(
                vehicleId: vehicleId,
                maintenanceTypeId: maintenanceTypeId,
                maintenanceDate: maintenanceDate,
                mileage: mileage,
                cost: Value(cost),
                shopName: Value(shopName),
                memo: Value(memo),
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
            );

        await (_database.update(_database.vehicles)..where(
              (v) =>
                  v.id.equals(vehicleId) &
                  v.currentMileage.isSmallerThanValue(mileage),
            ))
            .write(
              VehiclesCompanion(
                currentMileage: Value(mileage),
                mileageUpdatedAt: Value(timestamp),
                updatedAt: Value(timestamp),
              ),
            );

        return id;
      });
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to save maintenance record for vehicle $vehicleId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The interval in force for a vehicle: its own override if it set one,
  /// otherwise the type's recommendation.
  Stream<MaintenanceInterval> watchInterval({
    required int vehicleId,
    required int maintenanceTypeId,
  }) {
    final query = _database.select(_database.maintenanceTypes).join([
      leftOuterJoin(
        _database.vehicleMaintenanceSettings,
        _database.vehicleMaintenanceSettings.maintenanceTypeId.equalsExp(
              _database.maintenanceTypes.id,
            ) &
            _database.vehicleMaintenanceSettings.vehicleId.equals(vehicleId),
      ),
    ])..where(_database.maintenanceTypes.id.equals(maintenanceTypeId));

    return query.watchSingle().map((row) {
      final type = row.readTable(_database.maintenanceTypes);
      final override = row.readTableOrNull(
        _database.vehicleMaintenanceSettings,
      );
      return MaintenanceInterval(
        distanceKm: override?.distanceInterval ?? type.defaultDistanceInterval,
        months: override?.timeIntervalMonths ?? type.defaultTimeIntervalMonths,
      );
    });
  }

  /// The full picture for one maintenance type on one vehicle.
  ///
  /// One query rather than three combined streams: the odometer, the last
  /// record and the interval all feed the same answer, and Drift re-runs this
  /// whenever any of the four tables change.
  Stream<MaintenanceStatus?> watchStatus({
    required int vehicleId,
    required String typeCode,
    DateTime Function() clock = DateTime.now,
  }) {
    return _database
        .customSelect(
          '''
          SELECT
            v.current_mileage             AS current_mileage,
            t.id                          AS type_id,
            t.name                        AS type_name,
            COALESCE(s.distance_interval, t.default_distance_interval)
                                          AS distance_interval,
            COALESCE(s.time_interval_months, t.default_time_interval_months)
                                          AS time_interval_months,
            r.maintenance_date            AS last_service_date,
            r.mileage                     AS last_service_mileage
          FROM vehicles v
          JOIN maintenance_types t ON t.code = ?2
          LEFT JOIN vehicle_maintenance_settings s
            ON s.vehicle_id = v.id AND s.maintenance_type_id = t.id
          LEFT JOIN maintenance_records r ON r.id = (
            SELECT r2.id FROM maintenance_records r2
            WHERE r2.vehicle_id = v.id AND r2.maintenance_type_id = t.id
            ORDER BY r2.maintenance_date DESC, r2.id DESC
            LIMIT 1
          )
          WHERE v.id = ?1
          ''',
          variables: [
            Variable.withInt(vehicleId),
            Variable.withString(typeCode),
          ],
          readsFrom: {
            _database.vehicles,
            _database.maintenanceTypes,
            _database.vehicleMaintenanceSettings,
            _database.maintenanceRecords,
          },
        )
        .watchSingleOrNull()
        .map((row) {
          if (row == null) {
            return null;
          }

          final interval = MaintenanceInterval(
            distanceKm: row.read<int?>('distance_interval'),
            months: row.read<int?>('time_interval_months'),
          );
          final lastServiceDate = row.read<DateTime?>('last_service_date');
          final lastServiceMileage = row.read<int?>('last_service_mileage');

          return MaintenanceStatus(
            typeId: row.read<int>('type_id'),
            typeName: row.read<String>('type_name'),
            interval: interval,
            lastServiceDate: lastServiceDate,
            lastServiceMileage: lastServiceMileage,
            due: lastServiceDate == null || lastServiceMileage == null
                ? null
                : calculateMaintenanceDue(
                    lastServiceDate: lastServiceDate,
                    lastServiceMileage: lastServiceMileage,
                    interval: interval,
                    currentMileage: row.read<int>('current_mileage'),
                    today: clock(),
                  ),
          );
        });
  }

  /// Overrides the interval for one vehicle.
  Future<void> setInterval({
    required int vehicleId,
    required int maintenanceTypeId,
    required MaintenanceInterval interval,
  }) async {
    try {
      await _database
          .into(_database.vehicleMaintenanceSettings)
          .insertOnConflictUpdate(
            VehicleMaintenanceSettingsCompanion.insert(
              vehicleId: vehicleId,
              maintenanceTypeId: maintenanceTypeId,
              distanceInterval: Value(interval.distanceKm),
              timeIntervalMonths: Value(interval.months),
            ),
          );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to save interval for vehicle $vehicleId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => MaintenanceRepository(ref.watch(appDatabaseProvider)),
);

/// The built-in 엔진오일 type. Slice 3 replaces this with the full catalogue.
final engineOilTypeProvider = FutureProvider<MaintenanceType>(
  (ref) => ref.watch(maintenanceRepositoryProvider).engineOilType(),
);

/// 엔진오일 status for the vehicle the home screen is showing.
///
/// Emits null when no vehicle exists yet — the first-use empty state.
final engineOilStatusProvider = StreamProvider<MaintenanceStatus?>((
  ref,
) async* {
  final vehicle = await ref.watch(currentVehicleProvider.future);
  if (vehicle == null) {
    yield null;
    return;
  }
  yield* ref
      .watch(maintenanceRepositoryProvider)
      .watchStatus(vehicleId: vehicle.id, typeCode: engineOilTypeCode);
});

/// Every maintenance record for the current vehicle, most recent first.
final maintenanceRecordsProvider = StreamProvider<List<MaintenanceRecord>>((
  ref,
) async* {
  final vehicle = await ref.watch(currentVehicleProvider.future);
  if (vehicle == null) {
    yield const [];
    return;
  }
  yield* ref.watch(maintenanceRepositoryProvider).watchRecords(vehicle.id);
});
