import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/core/database/database_providers.dart';
import 'package:car_log/features/ai/data/ai_credentials.dart';
import 'package:car_log/features/notification/data/notification_scheduler_port.dart';
import 'package:car_log/features/receipt/data/receipt_picker.dart';
import 'package:car_log/core/storage/secure_store.dart';
import 'package:car_log/features/receipt/data/receipt_storage.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_ai_provider.dart';
import 'fake_notification_scheduler.dart';
import 'fake_receipt_picker.dart';
import 'in_memory_secure_store.dart';
import 'test_database.dart';

/// Boots the real app against an in-memory database.
///
/// Returns the container so a test can reach repositories directly to arrange
/// state or assert what was written.
({Widget app, ProviderContainer container}) buildTestApp() {
  final database = openTestDatabase();
  final picker = FakeReceiptPicker();
  final ai = FakeAiProvider();
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
      aiProvidersProvider.overrideWithValue([ai]),
      secureStoreProvider.overrideWithValue(InMemorySecureStore()),
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
///
/// [until] makes the wait a condition rather than a duration. A fixed delay
/// that is comfortable on a developer's machine is not comfortable on a shared
/// CI runner, which is how this test started failing only in CI.
Future<void> tapAndAwaitIo(
  WidgetTester tester,
  Finder finder, {
  Finder? until,
}) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await settle(tester);

  if (until == null) {
    return;
  }
  for (var attempt = 0; attempt < 60 && until.evaluate().isEmpty; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await settle(tester);
  }
}

/// The stand-in AI provider behind [buildTestApp].
FakeAiProvider aiOf(ProviderContainer container) =>
    container.read(aiProvidersProvider).single as FakeAiProvider;

/// Connects the fake provider as if the user had entered a key and picked it.
Future<void> connectFakeAi(ProviderContainer container) async {
  final credentials = container.read(aiCredentialsProvider);
  await credentials.saveApiKey('fake', 'test-key');
  await credentials.select('fake');
}

/// Reads the vehicles as a Future, for the same reason as
/// [readMaintenanceTypes]: a widget test must not await a Drift stream.
Future<List<Vehicle>> readVehicles(ProviderContainer container) {
  final database = container.read(appDatabaseProvider);
  return (database.select(
    database.vehicles,
  )..orderBy([(v) => OrderingTerm.asc(v.createdAt)])).get();
}

/// Scrolls the current screen until [finder] is on screen.
///
/// The home screen is taller than a phone: the car and the score sit above the
/// maintenance status, and the record list below it. A test asserting on
/// something further down has to scroll, the same as a user.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  // Screens carry more than one scrollable — a chip row or a badge strip
  // inside the page's own list — so the target has to be named. The page's
  // list is the outermost, and therefore the first in tree order.
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 20,
  );
  await settle(tester);
}

/// Pumps long enough for the home screen's animations to land.
///
/// The odometer rolls up over about a second, so a test reading its text too
/// early sees a number mid-count.
Future<void> settleAnimations(WidgetTester tester) =>
    settle(tester, frames: 80);
