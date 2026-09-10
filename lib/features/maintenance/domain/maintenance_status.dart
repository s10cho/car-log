import 'package:meta/meta.dart';

import 'maintenance_schedule.dart';

/// Everything the home screen needs to say about one maintenance type.
@immutable
class MaintenanceStatus {
  const MaintenanceStatus({
    required this.typeId,
    required this.typeName,
    required this.interval,
    this.lastServiceDate,
    this.lastServiceMileage,
    this.due,
  });

  final int typeId;
  final String typeName;
  final MaintenanceInterval interval;

  /// Null until the user records this maintenance for the first time.
  final DateTime? lastServiceDate;
  final int? lastServiceMileage;

  /// Null when there is no record yet, or when the interval has no dimension
  /// to project along.
  final MaintenanceDue? due;

  bool get hasRecord => lastServiceDate != null;
}
