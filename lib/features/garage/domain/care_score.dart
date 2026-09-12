import 'package:meta/meta.dart';

import '../../maintenance/domain/maintenance_schedule.dart';
import '../../maintenance/domain/maintenance_status.dart';

/// How well a vehicle is being looked after, 0–100.
///
/// The app's job is to answer "is my car fine?" at a glance. A list of items
/// makes the reader do that arithmetic themselves; one number does it for them,
/// and gives them something to improve.
@immutable
class CareScore {
  const CareScore({
    required this.value,
    required this.overdue,
    required this.dueSoon,
    required this.healthy,
    required this.mileageStale,
  });

  /// 0–100. Higher is better.
  final int value;

  final int overdue;
  final int dueSoon;
  final int healthy;

  /// Whether the odometer is too old to trust the distance-based items.
  final bool mileageStale;

  /// Nothing tracked yet — the score is not meaningful, so callers show a
  /// prompt instead of a zero the user did not earn.
  bool get isUnrated => overdue + dueSoon + healthy == 0;

  CareGrade get grade => switch (value) {
    >= 90 => CareGrade.excellent,
    >= 70 => CareGrade.good,
    >= 40 => CareGrade.attention,
    _ => CareGrade.urgent,
  };
}

/// The band a score falls in, which drives wording and colour.
enum CareGrade {
  excellent('아주 좋아요'),
  good('괜찮아요'),
  attention('살펴볼 때'),
  urgent('정비가 필요해요');

  const CareGrade(this.label);

  final String label;
}

/// Penalty applied for each item past its due point.
const int _overduePenalty = 25;

/// Penalty applied for each item approaching its due point.
const int _dueSoonPenalty = 8;

/// Penalty for an odometer nobody has confirmed in a while.
const int _staleMileagePenalty = 10;

/// Scores a vehicle from the items the user actually tracks.
///
/// Only tracked items count. Penalising someone for never recording their
/// coolant would make the score a judgement on the catalogue rather than on
/// their car, and every new user would start at zero.
CareScore calculateCareScore({
  required List<MaintenanceStatus> statuses,
  required bool mileageStale,
}) {
  final tracked = statuses.where((status) => status.hasRecord).toList();

  var overdue = 0;
  var dueSoon = 0;
  var healthy = 0;
  for (final status in tracked) {
    switch (status.due?.urgency) {
      case MaintenanceUrgency.overdue:
        overdue++;
      case MaintenanceUrgency.dueSoon:
        dueSoon++;
      case MaintenanceUrgency.ok:
        healthy++;
      case null:
        // No interval to judge by; neither credit nor blame.
        break;
    }
  }

  if (overdue + dueSoon + healthy == 0) {
    return CareScore(
      value: 0,
      overdue: 0,
      dueSoon: 0,
      healthy: 0,
      mileageStale: mileageStale,
    );
  }

  var score = 100;
  score -= overdue * _overduePenalty;
  score -= dueSoon * _dueSoonPenalty;
  if (mileageStale) {
    score -= _staleMileagePenalty;
  }

  return CareScore(
    value: score.clamp(0, 100),
    overdue: overdue,
    dueSoon: dueSoon,
    healthy: healthy,
    mileageStale: mileageStale,
  );
}
