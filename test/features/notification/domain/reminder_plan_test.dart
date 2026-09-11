import 'package:car_log/features/maintenance/domain/maintenance_schedule.dart';
import 'package:car_log/features/maintenance/domain/maintenance_status.dart';
import 'package:car_log/features/notification/domain/reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3, 1, 14, 30);

  MaintenanceStatus status({
    int typeId = 1,
    String typeName = '엔진오일',
    DateTime? dueDate,
    int? dueMileage,
    MaintenanceUrgency urgency = MaintenanceUrgency.ok,
  }) => MaintenanceStatus(
    typeId: typeId,
    typeName: typeName,
    isBuiltIn: true,
    interval: const MaintenanceInterval(distanceKm: 10000, months: 12),
    lastServiceDate: DateTime(2025, 6, 1),
    lastServiceMileage: 20000,
    due: MaintenanceDue(
      urgency: urgency,
      dueDate: dueDate,
      dueMileage: dueMileage,
      remainingDays: dueDate?.difference(DateTime(2026, 3, 1)).inDays,
    ),
  );

  List<Reminder> plan({
    List<MaintenanceStatus>? statuses,
    ReminderSettings settings = const ReminderSettings(),
    Set<int> muted = const {},
    DateTime? at,
  }) => planReminders(
    vehicleId: 1,
    vehicleName: '내 아반떼',
    statuses: statuses ?? [status(dueDate: DateTime(2026, 6, 1))],
    settings: settings,
    now: at ?? now,
    mutedTypeIds: muted,
  );

  group('what gets a reminder', () {
    test('an item with a due date does', () {
      expect(plan(), hasLength(1));
    });

    test('a distance-only item does not — there is no date to fire on', () {
      final reminders = plan(statuses: [status(dueMileage: 40000)]);

      expect(reminders, isEmpty);
    });

    test('an item that was never recorded does not', () {
      const never = MaintenanceStatus(
        typeId: 1,
        typeName: '엔진오일',
        isBuiltIn: true,
        interval: MaintenanceInterval(months: 12),
      );

      expect(plan(statuses: [never]), isEmpty);
    });

    test('nothing at all when reminders are switched off', () {
      expect(plan(settings: const ReminderSettings(enabled: false)), isEmpty);
    });

    test('a muted item does not', () {
      expect(plan(muted: {1}), isEmpty);
    });

    test('muting one item leaves the others alone', () {
      final reminders = plan(
        statuses: [
          status(dueDate: DateTime(2026, 6, 1)),
          status(typeId: 2, typeName: '와이퍼', dueDate: DateTime(2026, 7, 1)),
        ],
        muted: {1},
      );

      expect(reminders.map((r) => r.typeName), ['와이퍼']);
    });
  });

  group('when it fires', () {
    test('lead days before the due date, at the configured hour', () {
      final reminder = plan().single;

      expect(reminder.when, DateTime(2026, 5, 25, 9));
    });

    test('respects a different lead and hour', () {
      final reminder = plan(
        settings: const ReminderSettings(leadDays: 14, hourOfDay: 20),
      ).single;

      expect(reminder.when, DateTime(2026, 5, 18, 20));
    });

    test('never schedules in the past when the lead moment has gone', () {
      // 3일 뒤 만기인데 7일 전 알림이면 그 시점은 이미 지났다.
      final reminder = plan(statuses: [status(dueDate: DateTime(2026, 3, 4))])
          .single;

      expect(reminder.when, DateTime(2026, 3, 2, 9));
      expect(reminder.when.isAfter(now), isTrue);
    });

    test('uses today when the hour has not passed yet', () {
      final reminder = plan(
        statuses: [status(dueDate: DateTime(2026, 3, 4))],
        at: DateTime(2026, 3, 1, 7),
      ).single;

      expect(reminder.when, DateTime(2026, 3, 1, 9));
    });

    test('an overdue item is nudged at the next slot', () {
      final reminder = plan(
        statuses: [
          status(
            dueDate: DateTime(2026, 1, 15),
            urgency: MaintenanceUrgency.overdue,
          ),
        ],
      ).single;

      expect(reminder.when, DateTime(2026, 3, 2, 9));
      expect(reminder.kind, ReminderKind.overdue);
    });

    test('reminders come back soonest first', () {
      final reminders = plan(
        statuses: [
          status(typeId: 1, typeName: '냉각수', dueDate: DateTime(2026, 12, 1)),
          status(typeId: 2, typeName: '와이퍼', dueDate: DateTime(2026, 4, 1)),
        ],
      );

      expect(reminders.map((r) => r.typeName), ['와이퍼', '냉각수']);
    });
  });

  group('what it says', () {
    test('an upcoming reminder names the item and the date', () {
      final reminder = plan().single;

      expect(reminder.title, '엔진오일 교체 시기가 다가옵니다');
      expect(reminder.body(now), '내 아반떼 · 92일 뒤 2026.06.01');
    });

    test('an overdue reminder says so', () {
      final reminder = plan(
        statuses: [
          status(
            dueDate: DateTime(2026, 1, 15),
            urgency: MaintenanceUrgency.overdue,
          ),
        ],
      ).single;

      expect(reminder.title, '엔진오일 교체 시기가 지났습니다');
      expect(reminder.body(now), '내 아반떼 · 2026.01.15 기준');
    });
  });
}
