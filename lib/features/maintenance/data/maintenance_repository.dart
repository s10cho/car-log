import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../receipt/data/receipt_storage.dart';
import '../../receipt/domain/picked_receipt.dart';
import '../../vehicle/data/vehicle_repository.dart';
import '../domain/maintenance_schedule.dart';
import '../domain/maintenance_status.dart';

/// Reads and writes maintenance records, types and per-vehicle intervals.
class MaintenanceRepository {
  const MaintenanceRepository(this._database, this._receipts);

  final AppDatabase _database;
  final ReceiptStorage _receipts;

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
    PickedReceipt? receipt,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();

    // The file is copied in before the transaction: a failed copy should stop
    // the record being written, and a rolled back transaction would otherwise
    // leave a stray file behind.
    final storedPath = receipt == null
        ? null
        : await _receipts.save(receipt.file);

    try {
      return await _database.transaction(() async {
        final receiptId = storedPath == null
            ? null
            : await _database
                  .into(_database.receiptAssets)
                  .insert(
                    ReceiptAssetsCompanion.insert(
                      relativePath: storedPath,
                      fileName: receipt!.fileName,
                      mimeType: receipt.mimeType,
                      createdAt: timestamp,
                    ),
                  );

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
                receiptAssetId: Value(receiptId),
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
      if (storedPath != null) {
        await _receipts.delete(storedPath);
      }
      throw LocalDatabaseException(
        'Failed to save maintenance record for vehicle $vehicleId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The receipt attached to a record, if any.
  Future<ReceiptAsset?> receiptFor(int recordId) async {
    final record = await (_database.select(
      _database.maintenanceRecords,
    )..where((r) => r.id.equals(recordId))).getSingleOrNull();

    final assetId = record?.receiptAssetId;
    if (assetId == null) {
      return null;
    }
    return (_database.select(
      _database.receiptAssets,
    )..where((a) => a.id.equals(assetId))).getSingleOrNull();
  }

  /// Every receipt belonging to a vehicle's records.
  ///
  /// Deleting a vehicle cascades its records away; the files have to be removed
  /// by hand or they sit in the documents directory forever.
  Future<List<ReceiptAsset>> receiptsForVehicle(int vehicleId) async {
    final query = _database.select(_database.receiptAssets).join([
      innerJoin(
        _database.maintenanceRecords,
        _database.maintenanceRecords.receiptAssetId.equalsExp(
          _database.receiptAssets.id,
        ),
      ),
    ])..where(_database.maintenanceRecords.vehicleId.equals(vehicleId));

    final rows = await query.get();
    return [for (final row in rows) row.readTable(_database.receiptAssets)];
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

  /// Every maintenance type with this vehicle's standing for it.
  ///
  /// One query rather than a stream per type: the odometer, the last record and
  /// the interval all feed the same answer, and Drift re-runs this whenever any
  /// of the four tables change. Types the user has never recorded come back too,
  /// with [MaintenanceStatus.hasRecord] false — the settings screen needs them
  /// even though the home screen hides them.
  Stream<List<MaintenanceStatus>> watchStatuses({
    required int vehicleId,
    DateTime Function() clock = DateTime.now,
  }) {
    return _database
        .customSelect(
          '''
          SELECT
            v.current_mileage             AS current_mileage,
            t.id                          AS type_id,
            t.name                        AS type_name,
            t.is_built_in                 AS is_built_in,
            COALESCE(s.distance_interval, t.default_distance_interval)
                                          AS distance_interval,
            COALESCE(s.time_interval_months, t.default_time_interval_months)
                                          AS time_interval_months,
            r.maintenance_date            AS last_service_date,
            r.mileage                     AS last_service_mileage
          FROM maintenance_types t
          JOIN vehicles v ON v.id = ?1
          LEFT JOIN vehicle_maintenance_settings s
            ON s.vehicle_id = v.id AND s.maintenance_type_id = t.id
          LEFT JOIN maintenance_records r ON r.id = (
            SELECT r2.id FROM maintenance_records r2
            WHERE r2.vehicle_id = v.id AND r2.maintenance_type_id = t.id
            ORDER BY r2.maintenance_date DESC, r2.id DESC
            LIMIT 1
          )
          ORDER BY t.is_built_in DESC, t.id ASC
          ''',
          variables: [Variable.withInt(vehicleId)],
          readsFrom: {
            _database.vehicles,
            _database.maintenanceTypes,
            _database.vehicleMaintenanceSettings,
            _database.maintenanceRecords,
          },
        )
        .watch()
        .map((rows) => rows.map((row) => _toStatus(row, clock)).toList());
  }

  MaintenanceStatus _toStatus(QueryRow row, DateTime Function() clock) {
    final interval = MaintenanceInterval(
      distanceKm: row.read<int?>('distance_interval'),
      months: row.read<int?>('time_interval_months'),
    );
    final lastServiceDate = row.read<DateTime?>('last_service_date');
    final lastServiceMileage = row.read<int?>('last_service_mileage');

    return MaintenanceStatus(
      typeId: row.read<int>('type_id'),
      typeName: row.read<String>('type_name'),
      isBuiltIn: row.read<bool>('is_built_in'),
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
  }

  /// Every vehicle's standing for every maintenance type.
  ///
  /// Reminders cover all cars, not just the one on screen, so scheduling needs
  /// the whole picture in one place.
  Stream<List<VehicleMaintenanceStatus>> watchAllStatuses({
    DateTime Function() clock = DateTime.now,
  }) {
    return _database
        .customSelect(
          '''
          SELECT
            v.id                          AS vehicle_id,
            v.display_name                AS vehicle_name,
            v.current_mileage             AS current_mileage,
            t.id                          AS type_id,
            t.name                        AS type_name,
            t.is_built_in                 AS is_built_in,
            COALESCE(s.distance_interval, t.default_distance_interval)
                                          AS distance_interval,
            COALESCE(s.time_interval_months, t.default_time_interval_months)
                                          AS time_interval_months,
            COALESCE(s.notification_enabled, 1)
                                          AS notification_enabled,
            r.maintenance_date            AS last_service_date,
            r.mileage                     AS last_service_mileage
          FROM vehicles v
          CROSS JOIN maintenance_types t
          LEFT JOIN vehicle_maintenance_settings s
            ON s.vehicle_id = v.id AND s.maintenance_type_id = t.id
          LEFT JOIN maintenance_records r ON r.id = (
            SELECT r2.id FROM maintenance_records r2
            WHERE r2.vehicle_id = v.id AND r2.maintenance_type_id = t.id
            ORDER BY r2.maintenance_date DESC, r2.id DESC
            LIMIT 1
          )
          ORDER BY v.created_at ASC, t.is_built_in DESC, t.id ASC
          ''',
          readsFrom: {
            _database.vehicles,
            _database.maintenanceTypes,
            _database.vehicleMaintenanceSettings,
            _database.maintenanceRecords,
          },
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => (
                  vehicleId: row.read<int>('vehicle_id'),
                  vehicleName: row.read<String>('vehicle_name'),
                  notificationEnabled: row.read<bool>('notification_enabled'),
                  status: _toStatus(row, clock),
                ),
              )
              .toList(),
        );
  }

  /// All maintenance types, built-in first.
  Stream<List<MaintenanceType>> watchTypes() {
    return (_database.select(_database.maintenanceTypes)..orderBy([
          (t) => OrderingTerm.desc(t.isBuiltIn),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .watch();
  }

  /// Adds a maintenance item the user defined. Returns its id.
  Future<int> createCustomType({
    required String name,
    int? distanceInterval,
    int? timeIntervalMonths,
  }) async {
    try {
      return await _database
          .into(_database.maintenanceTypes)
          .insert(
            MaintenanceTypesCompanion.insert(
              name: name,
              defaultDistanceInterval: Value(distanceInterval),
              defaultTimeIntervalMonths: Value(timeIntervalMonths),
            ),
          );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to create maintenance type "$name"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Renames a type and changes its recommended interval.
  ///
  /// Built-in types can be edited too — the shipped intervals are only
  /// recommendations, and a user who knows their car should be able to correct
  /// them once rather than per vehicle.
  Future<void> updateType({
    required int id,
    required String name,
    int? distanceInterval,
    int? timeIntervalMonths,
  }) async {
    try {
      await (_database.update(
        _database.maintenanceTypes,
      )..where((t) => t.id.equals(id))).write(
        MaintenanceTypesCompanion(
          name: Value(name),
          defaultDistanceInterval: Value(distanceInterval),
          defaultTimeIntervalMonths: Value(timeIntervalMonths),
        ),
      );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to update maintenance type $id',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Turns reminders on or off for one item on one vehicle.
  Future<void> setNotificationEnabled({
    required int vehicleId,
    required int maintenanceTypeId,
    required bool enabled,
  }) async {
    try {
      await _database
          .into(_database.vehicleMaintenanceSettings)
          .insertOnConflictUpdate(
            VehicleMaintenanceSettingsCompanion.insert(
              vehicleId: vehicleId,
              maintenanceTypeId: maintenanceTypeId,
              notificationEnabled: Value(enabled),
            ),
          );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to change reminder setting for vehicle $vehicleId',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// How many records of this type exist across all vehicles.
  ///
  /// The UI asks before offering to delete a type: records reference it, so
  /// removing one that is in use would either fail or take history with it.
  Future<int> recordCountForType(int typeId) async {
    final rows = await (_database.select(
      _database.maintenanceRecords,
    )..where((r) => r.maintenanceTypeId.equals(typeId))).get();
    return rows.length;
  }

  /// Deletes a user-defined type that nothing references.
  Future<void> deleteType(int id) async {
    try {
      await (_database.delete(
        _database.maintenanceTypes,
      )..where((t) => t.id.equals(id) & t.isBuiltIn.equals(false))).go();
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to delete maintenance type $id',
        cause: error,
        stackTrace: stackTrace,
      );
    }
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
  (ref) => MaintenanceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(receiptStorageProvider),
  ),
);

/// The built-in 엔진오일 type. Slice 3 replaces this with the full catalogue.
final engineOilTypeProvider = FutureProvider<MaintenanceType>(
  (ref) => ref.watch(maintenanceRepositoryProvider).engineOilType(),
);

/// One vehicle's standing for one maintenance type, plus whether reminders
/// are switched on for it.
typedef VehicleMaintenanceStatus = ({
  int vehicleId,
  String vehicleName,
  bool notificationEnabled,
  MaintenanceStatus status,
});

/// Every maintenance type's standing for the vehicle being shown.
///
/// Empty when no vehicle exists yet — the first-use empty state.
final maintenanceStatusesProvider = StreamProvider<List<MaintenanceStatus>>((
  ref,
) async* {
  final vehicle = await ref.watch(currentVehicleProvider.future);
  if (vehicle == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(maintenanceRepositoryProvider)
      .watchStatuses(vehicleId: vehicle.id);
});

/// The items the home screen lists: the ones the user actually tracks on this
/// vehicle, most pressing first.
///
/// Showing all ten built-in items on a brand new car would bury the one thing
/// that matters under nine rows of "기록 없음".
final trackedMaintenanceProvider = Provider<List<MaintenanceStatus>>((ref) {
  final statuses = ref.watch(maintenanceStatusesProvider).value ?? const [];
  return statuses.where((status) => status.hasRecord).toList()
    ..sort(compareByUrgency);
});

/// Every vehicle's standing for every item — what reminders are built from,
/// and what the detail screen reads.
final allMaintenanceStatusesProvider =
    StreamProvider<List<VehicleMaintenanceStatus>>(
      (ref) => ref.watch(maintenanceRepositoryProvider).watchAllStatuses(),
    );

/// All maintenance types, for the settings screen.
final maintenanceTypesProvider = StreamProvider<List<MaintenanceType>>(
  (ref) => ref.watch(maintenanceRepositoryProvider).watchTypes(),
);

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
