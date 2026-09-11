import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';
import 'notification_scheduler_port.dart';

final _log = Logger('notifications');

/// Android notification channel for maintenance reminders.
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'maintenance_reminders',
  '정비 알림',
  description: '교체 시기가 다가오거나 지난 정비 항목을 알려 줍니다.',
  importance: Importance.defaultImportance,
);

/// Wraps the local notification plugin.
///
/// Everything schedule-related is decided by [planReminders]; this class only
/// applies a plan and owns the platform details.
class NotificationService implements NotificationScheduler {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _ready = false;

  /// Payloads look like `vehicleId:typeId`, which is all the app needs to open
  /// the right maintenance detail.
  final StreamController<String> _taps = StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  /// Prepares the plugin and the timezone database.
  ///
  /// Safe to call more than once; later calls are no-ops.
  Future<void> initialize() async {
    if (_ready) {
      return;
    }

    tz_data.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is requested later, when the user turns reminders on,
          // so the prompt arrives with context rather than at first launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _taps.add(payload);
        }
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _ready = true;
  }

  /// Asks the user for permission. Returns whether reminders can be shown.
  @override
  Future<bool> requestPermission() async {
    await initialize();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  /// Replaces everything scheduled with [reminders].
  ///
  /// Cancel-then-schedule rather than a diff: the whole plan is recomputed from
  /// the database on every change, so there is no state to reconcile and no
  /// notification id to keep stable.
  @override
  Future<void> apply(List<Reminder> reminders, {required DateTime now}) async {
    await initialize();
    await _plugin.cancelAll();

    for (var index = 0; index < reminders.length; index++) {
      final reminder = reminders[index];
      try {
        await _plugin.zonedSchedule(
          id: index,
          title: reminder.title,
          body: reminder.body(now),
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          // Inexact on purpose: a maintenance reminder does not need to land on
          // the second, and exact alarms require a permission Android 12+ users
          // have to grant by hand.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: '${reminder.vehicleId}:${reminder.typeId}',
        );
      } on Object catch (error, stackTrace) {
        // One bad reminder must not stop the rest from being scheduled.
        _log.warning('Failed to schedule a reminder', error, stackTrace);
      }
    }

    _log.info('Scheduled ${reminders.length} reminder(s)');
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  /// The payload of the notification that launched the app, if any.
  @override
  Future<String?> launchPayload() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return (details?.didNotificationLaunchApp ?? false)
        ? details?.notificationResponse?.payload
        : null;
  }

  @visibleForTesting
  void dispose() => _taps.close();
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(FlutterLocalNotificationsPlugin());
  ref.onDispose(service.dispose);
  return service;
});
