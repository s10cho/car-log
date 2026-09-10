import 'package:drift/drift.dart';

import 'maintenance_types.dart';
import 'vehicles.dart';

/// One completed piece of maintenance.
///
/// [maintenanceDate] and [mileage] are required because the next due date is
/// calculated from them. Everything else is optional so that recording a
/// service stays a ten-second job.
class MaintenanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  IntColumn get maintenanceTypeId => integer().references(
    MaintenanceTypes,
    #id,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get maintenanceDate => dateTime()();

  /// Odometer reading at the time of the work, in kilometres.
  IntColumn get mileage => integer()();

  /// Cost in KRW.
  IntColumn get cost => integer().nullable()();
  TextColumn get shopName => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
