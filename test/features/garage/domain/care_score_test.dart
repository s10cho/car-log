import 'package:car_log/features/garage/domain/care_score.dart';
import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/maintenance/domain/maintenance_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MaintenanceStatus status({
    required int typeId,
    MaintenanceUrgency? urgency,
    bool recorded = true,
  }) => MaintenanceStatus(
    typeId: typeId,
    typeName: 'item $typeId',
    isBuiltIn: true,
    interval: const MaintenanceInterval(distanceKm: 10000, months: 12),
    lastServiceDate: recorded ? DateTime(2026, 1, 1) : null,
    lastServiceMileage: recorded ? 20000 : null,
    due: urgency == null
        ? null
        : MaintenanceDue(urgency: urgency, dueMileage: 30000),
  );

  CareScore score(
    List<MaintenanceStatus> statuses, {
    bool mileageStale = false,
  }) => calculateCareScore(statuses: statuses, mileageStale: mileageStale);

  group('nothing tracked yet', () {
    test('is unrated rather than zero', () {
      final result = score([
        status(typeId: 1, recorded: false),
        status(typeId: 2, recorded: false),
      ]);

      expect(result.isUnrated, isTrue);
      expect(result.healthy, 0);
    });

    test('an empty list is unrated', () {
      expect(score(const []).isUnrated, isTrue);
    });
  });

  group('scoring', () {
    test('everything healthy is a full score', () {
      final result = score([
        status(typeId: 1, urgency: MaintenanceUrgency.ok),
        status(typeId: 2, urgency: MaintenanceUrgency.ok),
      ]);

      expect(result.value, 100);
      expect(result.grade, CareGrade.excellent);
      expect(result.isUnrated, isFalse);
    });

    test('an approaching item costs a little', () {
      final result = score([
        status(typeId: 1, urgency: MaintenanceUrgency.ok),
        status(typeId: 2, urgency: MaintenanceUrgency.dueSoon),
      ]);

      expect(result.value, 92);
      expect(result.grade, CareGrade.excellent);
      expect(result.dueSoon, 1);
    });

    test('an overdue item costs a lot', () {
      final result = score([
        status(typeId: 1, urgency: MaintenanceUrgency.ok),
        status(typeId: 2, urgency: MaintenanceUrgency.overdue),
      ]);

      expect(result.value, 75);
      expect(result.grade, CareGrade.good);
      expect(result.overdue, 1);
    });

    test('several overdue items reach the bottom band', () {
      final result = score([
        for (var i = 0; i < 3; i++)
          status(typeId: i, urgency: MaintenanceUrgency.overdue),
      ]);

      expect(result.value, 25);
      expect(result.grade, CareGrade.urgent);
    });

    test('the score never goes below zero', () {
      final result = score([
        for (var i = 0; i < 10; i++)
          status(typeId: i, urgency: MaintenanceUrgency.overdue),
      ], mileageStale: true);

      expect(result.value, 0);
    });

    test('a stale odometer costs a little', () {
      final healthy = [status(typeId: 1, urgency: MaintenanceUrgency.ok)];

      expect(score(healthy).value, 100);
      expect(score(healthy, mileageStale: true).value, 90);
    });

    test('an item with no interval neither helps nor hurts', () {
      final withoutInterval = score([
        status(typeId: 1, urgency: MaintenanceUrgency.ok),
        status(typeId: 2),
      ]);

      expect(withoutInterval.value, 100);
      expect(withoutInterval.healthy, 1);
    });

    test('untracked items are ignored entirely', () {
      final result = score([
        status(typeId: 1, urgency: MaintenanceUrgency.ok),
        status(typeId: 2, recorded: false),
        status(typeId: 3, recorded: false),
      ]);

      // 냉각수를 한 번도 기록하지 않은 사람을 벌주지 않는다.
      expect(result.value, 100);
    });
  });

  group('grades', () {
    test('cover the whole range in order', () {
      final boundaries = <int, CareGrade>{
        100: CareGrade.excellent,
        90: CareGrade.excellent,
        89: CareGrade.good,
        70: CareGrade.good,
        69: CareGrade.attention,
        40: CareGrade.attention,
        39: CareGrade.urgent,
        0: CareGrade.urgent,
      };

      for (final entry in boundaries.entries) {
        final score = CareScore(
          value: entry.key,
          overdue: 0,
          dueSoon: 0,
          healthy: 1,
          mileageStale: false,
        );
        expect(score.grade, entry.value, reason: '${entry.key}점');
      }
    });
  });
}
