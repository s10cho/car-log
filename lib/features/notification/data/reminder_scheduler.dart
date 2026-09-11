import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maintenance/data/maintenance_repository.dart';
import '../domain/reminder_plan.dart';
import 'reminder_settings_repository.dart';

/// What the app should currently have scheduled.
///
/// Recomputed from scratch whenever a vehicle, record, interval or preference
/// changes. Nothing here talks to the platform — applying the plan is the
/// scheduler widget's job.
final reminderPlanProvider = StreamProvider<List<Reminder>>((ref) async* {
  final settings = await ref.watch(reminderSettingsProvider.future);
  if (!settings.enabled) {
    yield const [];
    return;
  }

  final repository = ref.watch(maintenanceRepositoryProvider);
  await for (final rows in repository.watchAllStatuses()) {
    yield _plan(rows, settings);
  }
});

List<Reminder> _plan(
  List<VehicleMaintenanceStatus> rows,
  ReminderSettings settings,
) {
  final byVehicle = <int, List<VehicleMaintenanceStatus>>{};
  for (final row in rows) {
    byVehicle.putIfAbsent(row.vehicleId, () => []).add(row);
  }

  final now = DateTime.now();
  final reminders = <Reminder>[];
  for (final entry in byVehicle.entries) {
    final vehicleRows = entry.value;
    reminders.addAll(
      planReminders(
        vehicleId: entry.key,
        vehicleName: vehicleRows.first.vehicleName,
        statuses: [for (final row in vehicleRows) row.status],
        settings: settings,
        now: now,
        mutedTypeIds: {
          for (final row in vehicleRows)
            if (!row.notificationEnabled) row.status.typeId,
        },
      ),
    );
  }

  reminders.sort((a, b) => a.when.compareTo(b.when));
  return reminders;
}
