import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reminder_plan.dart';
import 'notification_service.dart';

/// What the app needs from the platform to raise reminders.
///
/// A seam rather than an abstraction for its own sake: widget tests have no
/// notification plugin, and driving one from a test would prove nothing about
/// the rules, which [planReminders] already covers.
abstract interface class NotificationScheduler {
  Future<void> apply(List<Reminder> reminders, {required DateTime now});

  Future<bool> requestPermission();

  Future<String?> launchPayload();

  Stream<String> get taps;
}

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => ref.watch(notificationServiceProvider),
);
