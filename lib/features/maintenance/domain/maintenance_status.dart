import 'package:meta/meta.dart';

import 'maintenance_schedule.dart';

/// Everything the app needs to say about one maintenance type on one vehicle.
@immutable
class MaintenanceStatus {
  const MaintenanceStatus({
    required this.typeId,
    required this.typeName,
    required this.isBuiltIn,
    required this.interval,
    this.lastServiceDate,
    this.lastServiceMileage,
    this.due,
  });

  final int typeId;
  final String typeName;
  final bool isBuiltIn;
  final MaintenanceInterval interval;

  /// Null until the user records this maintenance for the first time.
  final DateTime? lastServiceDate;
  final int? lastServiceMileage;

  /// Null when there is no record yet, or when the interval has no dimension
  /// to project along.
  final MaintenanceDue? due;

  bool get hasRecord => lastServiceDate != null;

  /// Ordering for the home screen: what needs attention first.
  ///
  /// Items with no due point at all sort last — there is nothing to act on.
  int get urgencyRank => switch (due?.urgency) {
    MaintenanceUrgency.overdue => 0,
    MaintenanceUrgency.dueSoon => 1,
    MaintenanceUrgency.ok => 2,
    null => 3,
  };
}

/// Sorts by what needs doing soonest, then by how close it is.
int compareByUrgency(MaintenanceStatus a, MaintenanceStatus b) {
  final byRank = a.urgencyRank.compareTo(b.urgencyRank);
  if (byRank != 0) {
    return byRank;
  }
  final remainingA = a.due?.remainingDays;
  final remainingB = b.due?.remainingDays;
  if (remainingA != null && remainingB != null) {
    return remainingA.compareTo(remainingB);
  }
  return a.typeName.compareTo(b.typeName);
}
