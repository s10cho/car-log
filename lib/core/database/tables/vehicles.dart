import 'package:drift/drift.dart';

/// A vehicle the user manages. Multiple vehicles are supported by the schema
/// from the start; switching between them arrives in Slice 2.
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// What the user calls this car, e.g. "내 아반떼".
  TextColumn get displayName => text().withLength(min: 1, max: 40)();

  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get modelYear => integer().nullable()();

  /// Filled in manually for now. Lookup by plate or VIN needs an API whose
  /// commercial availability is still unverified (docs/decisions.md).
  TextColumn get vin => text().nullable()();
  TextColumn get licensePlate => text().nullable()();

  /// Odometer reading in kilometres, and when the user last confirmed it.
  IntColumn get currentMileage => integer()();
  DateTimeColumn get mileageUpdatedAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
