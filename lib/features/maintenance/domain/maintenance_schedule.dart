import 'package:meta/meta.dart';

/// Distance left before a service is treated as 임박.
const int dueSoonDistanceKm = 1000;

/// Days left before a service is treated as 임박.
const int dueSoonDays = 30;

/// How often a maintenance type should be repeated.
///
/// Either dimension may be absent. When both are present the earlier of the two
/// wins, matching how the intervals are written on the box: "10,000 km 또는 12개월".
@immutable
class MaintenanceInterval {
  const MaintenanceInterval({this.distanceKm, this.months});

  final int? distanceKm;
  final int? months;

  /// An interval with neither dimension cannot produce a due point.
  bool get isEmpty => distanceKm == null && months == null;

  @override
  bool operator ==(Object other) =>
      other is MaintenanceInterval &&
      other.distanceKm == distanceKm &&
      other.months == months;

  @override
  int get hashCode => Object.hash(distanceKm, months);

  @override
  String toString() => 'MaintenanceInterval(km: $distanceKm, months: $months)';
}

/// How pressing the next service is.
enum MaintenanceUrgency {
  /// Still comfortably away.
  ok,

  /// Within [dueSoonDistanceKm] or [dueSoonDays] of being due.
  dueSoon,

  /// The due point has passed.
  overdue,
}

/// The result of projecting an interval forward from the last service.
@immutable
class MaintenanceDue {
  const MaintenanceDue({
    required this.urgency,
    this.dueMileage,
    this.dueDate,
    this.remainingDistanceKm,
    this.remainingDays,
  });

  final MaintenanceUrgency urgency;

  /// Odometer reading at which the service is due, when the interval has a
  /// distance dimension.
  final int? dueMileage;

  /// Date on which the service is due, when the interval has a time dimension.
  final DateTime? dueDate;

  /// Kilometres left; negative once the vehicle has driven past [dueMileage].
  final int? remainingDistanceKm;

  /// Days left; negative once [dueDate] has passed.
  final int? remainingDays;

  bool get isOverdue => urgency == MaintenanceUrgency.overdue;
}

/// Projects the next service from the last one.
///
/// Returns null when [interval] carries no dimension to project along — there
/// is nothing to be due, rather than something that is due now.
MaintenanceDue? calculateMaintenanceDue({
  required DateTime lastServiceDate,
  required int lastServiceMileage,
  required MaintenanceInterval interval,
  required int currentMileage,
  required DateTime today,
}) {
  if (interval.isEmpty) {
    return null;
  }

  int? dueMileage;
  int? remainingDistanceKm;
  if (interval.distanceKm case final int distance) {
    dueMileage = lastServiceMileage + distance;
    remainingDistanceKm = dueMileage - currentMileage;
  }

  DateTime? dueDate;
  int? remainingDays;
  if (interval.months case final int months) {
    dueDate = addMonths(lastServiceDate, months);
    remainingDays = _wholeDaysBetween(today, dueDate);
  }

  return MaintenanceDue(
    urgency: _urgencyOf(
      remainingDistanceKm: remainingDistanceKm,
      remainingDays: remainingDays,
    ),
    dueMileage: dueMileage,
    dueDate: dueDate,
    remainingDistanceKm: remainingDistanceKm,
    remainingDays: remainingDays,
  );
}

MaintenanceUrgency _urgencyOf({
  required int? remainingDistanceKm,
  required int? remainingDays,
}) {
  final distanceOverdue =
      remainingDistanceKm != null && remainingDistanceKm < 0;
  final timeOverdue = remainingDays != null && remainingDays < 0;
  if (distanceOverdue || timeOverdue) {
    return MaintenanceUrgency.overdue;
  }

  final distanceNear =
      remainingDistanceKm != null && remainingDistanceKm <= dueSoonDistanceKm;
  final timeNear = remainingDays != null && remainingDays <= dueSoonDays;
  if (distanceNear || timeNear) {
    return MaintenanceUrgency.dueSoon;
  }

  return MaintenanceUrgency.ok;
}

/// Adds [months] calendar months, clamping to the last day of the target month.
///
/// 1월 31일 + 1개월 is 2월 28일 (or 29일), not 3월 3일 — which is what plain
/// `DateTime` arithmetic would produce.
DateTime addMonths(DateTime date, int months) {
  final targetYear = date.year + (date.month - 1 + months) ~/ 12;
  final targetMonth = (date.month - 1 + months) % 12 + 1;
  final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  return DateTime(
    targetYear,
    targetMonth,
    date.day < lastDayOfTargetMonth ? date.day : lastDayOfTargetMonth,
  );
}

/// Whole days from [from] to [to], ignoring the time of day on both sides.
///
/// Comparing dates rather than instants keeps "3일 남음" stable regardless of
/// when during the day the app is opened, and immune to DST shifts.
int _wholeDaysBetween(DateTime from, DateTime to) {
  final fromDate = DateTime(from.year, from.month, from.day);
  final toDate = DateTime(to.year, to.month, to.day);
  return toDate.difference(fromDate).inDays;
}
