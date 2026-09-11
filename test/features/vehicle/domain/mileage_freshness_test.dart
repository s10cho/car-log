import 'package:car_log/features/vehicle/domain/mileage_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3, 1, 14, 30);

  bool stale(DateTime updatedAt) =>
      isMileageStale(updatedAt: updatedAt, now: now);

  test('a reading from today is fresh', () {
    expect(stale(DateTime(2026, 3, 1, 8)), isFalse);
  });

  test('a reading from last week is fresh', () {
    expect(stale(DateTime(2026, 2, 22)), isFalse);
  });

  test('the day before the threshold is still fresh', () {
    expect(stale(DateTime(2026, 1, 31)), isFalse);
  });

  test('the threshold itself is stale', () {
    expect(stale(DateTime(2026, 1, 30)), isTrue);
  });

  test('a reading from months ago is stale', () {
    expect(stale(DateTime(2025, 9, 1)), isTrue);
  });

  test('the count ignores the time of day', () {
    expect(
      daysSinceMileageUpdate(
        updatedAt: DateTime(2026, 2, 27, 23, 59),
        now: DateTime(2026, 3, 1, 0, 1),
      ),
      2,
    );
  });
}
