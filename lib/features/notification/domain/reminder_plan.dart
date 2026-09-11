import 'package:meta/meta.dart';

import '../../maintenance/domain/maintenance_schedule.dart';
import '../../maintenance/domain/maintenance_status.dart';

/// How the app is allowed to remind.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.leadDays = 7,
    this.hourOfDay = 9,
  });

  /// Master switch. Off means no reminder is ever scheduled.
  final bool enabled;

  /// How many days before the due date to raise the reminder.
  final int leadDays;

  /// Local hour the reminder fires at. Nobody wants a 03:00 notification.
  final int hourOfDay;

  ReminderSettings copyWith({bool? enabled, int? leadDays, int? hourOfDay}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        leadDays: leadDays ?? this.leadDays,
        hourOfDay: hourOfDay ?? this.hourOfDay,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.leadDays == leadDays &&
      other.hourOfDay == hourOfDay;

  @override
  int get hashCode => Object.hash(enabled, leadDays, hourOfDay);
}

/// Why a reminder is being raised.
enum ReminderKind {
  /// The due date is approaching.
  upcoming,

  /// The due date has already passed.
  overdue,
}

/// One notification the app intends to raise.
@immutable
class Reminder {
  const Reminder({
    required this.vehicleId,
    required this.vehicleName,
    required this.typeId,
    required this.typeName,
    required this.when,
    required this.kind,
    required this.dueDate,
  });

  final int vehicleId;
  final String vehicleName;
  final int typeId;
  final String typeName;

  /// Local time to fire.
  final DateTime when;
  final ReminderKind kind;
  final DateTime dueDate;

  String get title => switch (kind) {
    ReminderKind.upcoming => '$typeName 교체 시기가 다가옵니다',
    ReminderKind.overdue => '$typeName 교체 시기가 지났습니다',
  };

  String body(DateTime today) {
    final days = _wholeDaysBetween(today, dueDate);
    return switch (kind) {
      ReminderKind.upcoming =>
        '$vehicleName · $days일 뒤 ${_formatDate(dueDate)}',
      ReminderKind.overdue => '$vehicleName · ${_formatDate(dueDate)} 기준',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.vehicleId == vehicleId &&
      other.typeId == typeId &&
      other.when == when &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(vehicleId, typeId, when, kind);

  @override
  String toString() => 'Reminder($vehicleName/$typeName at $when, $kind)';
}

/// What the app should have scheduled, given the current data.
///
/// A pure function so the rules can be tested without a notification plugin:
/// everything platform-specific lives in the service that applies this plan.
///
/// Only items with a **time** dimension produce reminders. A distance-only
/// interval has no calendar date to fire on — the app cannot know the odometer
/// moved while it is closed — so those show up as in-app status only.
List<Reminder> planReminders({
  required int vehicleId,
  required String vehicleName,
  required List<MaintenanceStatus> statuses,
  required ReminderSettings settings,
  required DateTime now,
  Set<int> mutedTypeIds = const {},
}) {
  if (!settings.enabled) {
    return const [];
  }

  final reminders = <Reminder>[];
  for (final status in statuses) {
    if (mutedTypeIds.contains(status.typeId)) {
      continue;
    }
    final dueDate = status.due?.dueDate;
    if (dueDate == null) {
      continue;
    }

    final overdue = status.due!.urgency == MaintenanceUrgency.overdue;
    final when = overdue
        ? _nextNotificationSlot(now, settings.hourOfDay)
        : _laterOf(
            _at(
              dueDate.subtract(Duration(days: settings.leadDays)),
              settings.hourOfDay,
            ),
            _nextNotificationSlot(now, settings.hourOfDay),
          );

    reminders.add(
      Reminder(
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        typeId: status.typeId,
        typeName: status.typeName,
        when: when,
        kind: overdue ? ReminderKind.overdue : ReminderKind.upcoming,
        dueDate: dueDate,
      ),
    );
  }

  reminders.sort((a, b) => a.when.compareTo(b.when));
  return reminders;
}

/// The next time today or tomorrow at [hour] that is still in the future.
DateTime _nextNotificationSlot(DateTime now, int hour) {
  final todaysSlot = _at(now, hour);
  return todaysSlot.isAfter(now)
      ? todaysSlot
      : _at(now.add(const Duration(days: 1)), hour);
}

DateTime _at(DateTime date, int hour) =>
    DateTime(date.year, date.month, date.day, hour);

DateTime _laterOf(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

int _wholeDaysBetween(DateTime from, DateTime to) => DateTime(
  to.year,
  to.month,
  to.day,
).difference(DateTime(from.year, from.month, from.day)).inDays;

String _formatDate(DateTime date) =>
    '${date.year}.${_two(date.month)}.${_two(date.day)}';

String _two(int value) => value.toString().padLeft(2, '0');
