import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/core/database/database_providers.dart';
import 'package:car_log/features/settings/data/app_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig(
    environment: AppEnvironment.dev,
    appName: 'Car Log Integration',
    databaseName: 'car_log_integration_test',
    verboseLogging: true,
  );

  Widget app(ProviderContainer container) =>
      UncontrolledProviderScope(container: container, child: const CarLogApp());

  ProviderContainer container() => ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(config)],
  );

  testWidgets('opens the on-device database and renders the shell', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await tester.pumpAndSettle();

    expect(find.text('아직 등록된 차량이 없습니다'), findsOneWidget);

    final database = scope.read(appDatabaseProvider);
    expect(database, isA<AppDatabase>());
    await database.customSelect('SELECT 1').get();
  });

  testWidgets('local data survives a restart of the provider container', (
    tester,
  ) async {
    final first = container();
    await tester.pumpWidget(app(first));
    await tester.pumpAndSettle();

    final repository = first.read(appPreferencesRepositoryProvider);
    await repository.write('foundation_smoke', 'persisted');
    first.dispose();

    final second = container();
    addTearDown(second.dispose);
    await tester.pumpWidget(app(second));
    await tester.pumpAndSettle();

    expect(
      await second
          .read(appPreferencesRepositoryProvider)
          .read('foundation_smoke'),
      'persisted',
    );

    await second
        .read(appPreferencesRepositoryProvider)
        .remove('foundation_smoke');
  });
}
