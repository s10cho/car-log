import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lastService = DateTime(2026, 1, 10);

  MaintenanceDue? due({
    MaintenanceInterval interval = const MaintenanceInterval(
      distanceKm: 10000,
      months: 12,
    ),
    int lastServiceMileage = 30000,
    int currentMileage = 30000,
    DateTime? today,
  }) => calculateMaintenanceDue(
    lastServiceDate: lastService,
    lastServiceMileage: lastServiceMileage,
    interval: interval,
    currentMileage: currentMileage,
    today: today ?? DateTime(2026, 1, 10),
  );

  group('projection', () {
    test('projects the due mileage and date from the last service', () {
      final result = due()!;

      expect(result.dueMileage, 40000);
      expect(result.dueDate, DateTime(2027, 1, 10));
    });

    test('reports distance and days remaining', () {
      final result = due(currentMileage: 35000, today: DateTime(2026, 7, 10))!;

      expect(result.remainingDistanceKm, 5000);
      expect(result.remainingDays, 184);
    });

    test('omits the distance dimension when the interval has none', () {
      final result = due(interval: const MaintenanceInterval(months: 12))!;

      expect(result.dueMileage, isNull);
      expect(result.remainingDistanceKm, isNull);
      expect(result.dueDate, DateTime(2027, 1, 10));
    });

    test('omits the time dimension when the interval has none', () {
      final result = due(
        interval: const MaintenanceInterval(distanceKm: 10000),
      )!;

      expect(result.dueDate, isNull);
      expect(result.remainingDays, isNull);
      expect(result.dueMileage, 40000);
    });

    test('returns null when the interval has no dimension at all', () {
      expect(due(interval: const MaintenanceInterval()), isNull);
    });
  });

  group('urgency', () {
    test('is ok when both dimensions are far away', () {
      expect(due()!.urgency, MaintenanceUrgency.ok);
    });

    test('is dueSoon within 1,000 km even if the date is far off', () {
      final result = due(currentMileage: 39100)!;

      expect(result.remainingDistanceKm, 900);
      expect(result.urgency, MaintenanceUrgency.dueSoon);
    });

    test('is dueSoon within 30 days even if the distance is far off', () {
      final result = due(today: DateTime(2026, 12, 20))!;

      expect(result.remainingDays, 21);
      expect(result.urgency, MaintenanceUrgency.dueSoon);
    });

    test('is overdue once the mileage is past, whatever the date says', () {
      final result = due(currentMileage: 40001)!;

      expect(result.remainingDistanceKm, -1);
      expect(result.urgency, MaintenanceUrgency.overdue);
      expect(result.isOverdue, isTrue);
    });

    test('is overdue once the date is past, whatever the odometer says', () {
      final result = due(today: DateTime(2027, 1, 11))!;

      expect(result.remainingDays, -1);
      expect(result.urgency, MaintenanceUrgency.overdue);
    });

    test('treats the exact due point as not yet overdue', () {
      final result = due(currentMileage: 40000, today: DateTime(2027, 1, 10))!;

      expect(result.remainingDistanceKm, 0);
      expect(result.remainingDays, 0);
      expect(result.urgency, MaintenanceUrgency.dueSoon);
    });

    test('the earlier dimension wins when the two disagree', () {
      // 거리는 여유롭지만 기간이 지났다.
      final result = due(currentMileage: 30000, today: DateTime(2027, 6, 1))!;

      expect(result.remainingDistanceKm, 10000);
      expect(result.urgency, MaintenanceUrgency.overdue);
    });
  });

  group('addMonths', () {
    test('adds within the same year', () {
      expect(addMonths(DateTime(2026, 1, 10), 3), DateTime(2026, 4, 10));
    });

    test('rolls over the year boundary', () {
      expect(addMonths(DateTime(2026, 11, 10), 3), DateTime(2027, 2, 10));
    });

    test('clamps to the last day of a shorter month', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('clamps to 29 February in a leap year', () {
      expect(addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    });

    test('keeps the day when the target month is long enough', () {
      expect(addMonths(DateTime(2026, 1, 30), 2), DateTime(2026, 3, 30));
    });
  });

  group('day counting', () {
    test('ignores the time of day on both sides', () {
      final morning = calculateMaintenanceDue(
        lastServiceDate: DateTime(2026, 1, 10, 23, 59),
        lastServiceMileage: 0,
        interval: const MaintenanceInterval(months: 1),
        currentMileage: 0,
        today: DateTime(2026, 1, 20, 0, 1),
      )!;

      expect(morning.remainingDays, 21);
    });
  });
}
