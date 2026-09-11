/// How long an odometer reading is treated as current.
///
/// Long enough not to nag, short enough that "다음 교체까지 N km" has not drifted
/// far: a typical driver covers a few hundred kilometres in a month.
const int mileageStaleAfterDays = 30;

/// Whether the app should ask the user to confirm the odometer.
///
/// Automatic mileage from the manufacturer is not available (docs/connected-car.md),
/// so a stale reading quietly makes every distance-based due point wrong. The
/// user cannot tell that from looking at the screen, so the app asks.
bool isMileageStale({required DateTime updatedAt, required DateTime now}) =>
    daysSinceMileageUpdate(updatedAt: updatedAt, now: now) >=
    mileageStaleAfterDays;

/// Whole days since the reading, counted by date so the answer does not change
/// with the time of day.
int daysSinceMileageUpdate({
  required DateTime updatedAt,
  required DateTime now,
}) {
  final from = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
  final to = DateTime(now.year, now.month, now.day);
  return to.difference(from).inDays;
}
