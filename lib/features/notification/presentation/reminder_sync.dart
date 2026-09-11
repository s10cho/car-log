import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/navigation/app_router.dart';
import '../../../app/navigation/app_routes.dart';
import '../data/notification_scheduler_port.dart';
import '../data/reminder_scheduler.dart';

/// Keeps the platform's scheduled notifications in step with the plan, and
/// turns a notification tap into navigation.
///
/// Sits above the router so it is mounted for the whole life of the app.
class ReminderSync extends ConsumerStatefulWidget {
  const ReminderSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends ConsumerState<ReminderSync> {
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    _taps = scheduler.taps.listen(_open);

    final launchPayload = await scheduler.launchPayload();
    if (launchPayload != null) {
      _open(launchPayload);
    }
  }

  /// Payloads are `vehicleId:typeId`.
  void _open(String payload) {
    final parts = payload.split(':');
    if (parts.length != 2) {
      return;
    }
    final vehicleId = int.tryParse(parts[0]);
    final typeId = int.tryParse(parts[1]);
    if (vehicleId == null || typeId == null || !mounted) {
      return;
    }

    ref
        .read(routerProvider)
        .pushNamed(
          AppRoutes.maintenanceDetailName,
          pathParameters: {'vehicleId': '$vehicleId', 'typeId': '$typeId'},
        );
  }

  @override
  void dispose() {
    _taps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(reminderPlanProvider, (_, next) {
      final reminders = next.value;
      if (reminders != null) {
        unawaited(
          ref
              .read(notificationSchedulerProvider)
              .apply(reminders, now: DateTime.now()),
        );
      }
    });

    return widget.child;
  }
}
