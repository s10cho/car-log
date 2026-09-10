import 'package:drift/drift.dart';

/// A kind of maintenance work, such as 엔진오일 or 와이퍼.
///
/// Slice 1 seeds only 엔진오일 — the one item the product spec gives concrete
/// interval numbers for. The rest of the built-in catalogue and user-defined
/// types arrive in Slice 3.
class MaintenanceTypes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable identifier for built-in types, e.g. `engine_oil`. Null for types
  /// the user creates, which are identified by [name] alone.
  TextColumn get code => text().nullable().unique()();

  TextColumn get name => text().withLength(min: 1, max: 40)();

  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// Recommended interval, used when a vehicle has no override of its own.
  /// Either may be null; a type with neither cannot produce a due date.
  IntColumn get defaultDistanceInterval => integer().nullable()();
  IntColumn get defaultTimeIntervalMonths => integer().nullable()();
}
