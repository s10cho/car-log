import 'dart:async';

import 'package:car_log/features/notification/data/notification_scheduler_port.dart';
import 'package:car_log/features/notification/domain/reminder_plan.dart';

/// Stands in for the notification plugin in widget tests.
///
/// Records what the app asked the platform to do so a test can assert on the
/// plan without a real notification ever being scheduled.
class FakeNotificationScheduler implements NotificationScheduler {
  final List<List<Reminder>> applied = [];
  final StreamController<String> _taps = StreamController<String>.broadcast();

  bool permissionGranted = true;
  int permissionRequests = 0;
  String? launchPayloadValue;

  List<Reminder> get lastPlan => applied.isEmpty ? const [] : applied.last;

  @override
  Future<void> apply(List<Reminder> reminders, {required DateTime now}) async {
    applied.add(reminders);
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<String?> launchPayload() async => launchPayloadValue;

  @override
  Stream<String> get taps => _taps.stream;

  /// Simulates the user tapping a notification.
  void tap(String payload) => _taps.add(payload);

  void dispose() => _taps.close();
}
