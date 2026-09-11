import 'package:drift/drift.dart';

import 'maintenance_types.dart';
import 'vehicles.dart';

/// Per-vehicle override of a maintenance type's recommended interval.
///
/// A row exists only when the user changed something; otherwise the type's
/// defaults apply.
class VehicleMaintenanceSettings extends Table {
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  IntColumn get maintenanceTypeId => integer().references(
    MaintenanceTypes,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get distanceInterval => integer().nullable()();
  IntColumn get timeIntervalMonths => integer().nullable()();

  /// Whether reminders are raised for this item on this vehicle.
  /// Absent row means enabled — the default is to remind.
  BoolColumn get notificationEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {vehicleId, maintenanceTypeId};
}
