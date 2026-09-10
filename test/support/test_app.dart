import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:car_log/core/database/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

/// Boots the real app against an in-memory database.
///
/// Returns the container so a test can reach repositories directly to arrange
/// state or assert what was written.
({Widget app, ProviderContainer container}) buildTestApp() {
  final database = openTestDatabase();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.of(AppEnvironment.dev)),
      appDatabaseProvider.overrideWithValue(database),
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
