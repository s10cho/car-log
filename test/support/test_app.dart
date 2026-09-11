import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/core/database/database_providers.dart';
import 'package:car_log/features/notification/data/notification_scheduler_port.dart';
import 'package:car_log/features/receipt/data/receipt_picker.dart';
import 'package:car_log/features/receipt/data/receipt_storage.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_scheduler.dart';
import 'fake_receipt_picker.dart';
import 'test_database.dart';

/// Boots the real app against an in-memory database.
///
/// Returns the container so a test can reach repositories directly to arrange
/// state or assert what was written.
({Widget app, ProviderContainer container}) buildTestApp() {
  final database = openTestDatabase();
  final picker = FakeReceiptPicker();
  final notifications = FakeNotificationScheduler();
  addTearDown(notifications.dispose);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.of(AppEnvironment.dev)),
      appDatabaseProvider.overrideWithValue(database),
      // No notification plugin in a widget test; the rules are covered by
      // planReminders' own tests.
      notificationSchedulerProvider.overrideWithValue(notifications),
      // No camera or file system dialog in a widget test.
      receiptPickerProvider.overrideWithValue(picker),
      receiptStorageProvider.overrideWithValue(
        openTestReceiptStorage(database),
      ),
    ],
  );
  addTearDown(container.dispose);

  return (
    app: UncontrolledProviderScope(
      container: container,
      child: const CarLogApp(),
    ),
    container: container,
  );
}

/// Advances time without waiting for animations to finish.
///
/// [WidgetTester.pumpAndSettle] never returns while a [CircularProgressIndicator]
/// is on screen, and these screens show one while the database opens.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Reads the maintenance catalogue as a Future.
///
/// Widget tests must not await a Drift *stream* — the test binding holds the
/// clock its timers wait on, so `watchTypes().first` never returns.
Future<List<MaintenanceType>> readMaintenanceTypes(
  ProviderContainer container,
) {
  final database = container.read(appDatabaseProvider);
  return (database.select(database.maintenanceTypes)..orderBy([
        (t) => OrderingTerm.desc(t.isBuiltIn),
        (t) => OrderingTerm.asc(t.id),
      ]))
      .get();
}

/// The stand-in scheduler behind [buildTestApp], for asserting on what the app
/// asked the platform to schedule.
FakeNotificationScheduler notificationsOf(ProviderContainer container) =>
    container.read(notificationSchedulerProvider) as FakeNotificationScheduler;

/// The stand-in picker behind [buildTestApp].
FakeReceiptPicker pickerOf(ProviderContainer container) =>
    container.read(receiptPickerProvider) as FakeReceiptPicker;

/// Taps [finder] and lets real file I/O finish.
///
/// A widget test holds a fake clock, so `dart:io` work started by a tap — such
/// as copying a receipt into the app's storage — never completes unless the
/// real event loop is allowed to run.
Future<void> tapAndAwaitIo(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await settle(tester);
}
