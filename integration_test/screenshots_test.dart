import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:car_log/core/database/database_providers.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Walks the app and captures each screen.
///
/// Not an assertion suite — it exists so UI changes can be looked at. Run with
/// `flutter drive` (see test_driver/integration_test.dart).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig(
    environment: AppEnvironment.dev,
    appName: 'Car로그 Shots',
    databaseName: 'car_log_shots',
    verboseLogging: true,
  );

  ProviderContainer container() => ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(config)],
  );

  Widget app(ProviderContainer scope) =>
      UncontrolledProviderScope(container: scope, child: const CarLogApp());

  Future<void> settle(WidgetTester tester, {int frames = 40}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    // No pumpAndSettle: the 3D car animates forever, so settling never
    // finishes. A fixed number of frames is enough for a screenshot.
    await settle(tester, frames: 20);
    await binding.takeScreenshot(name);
  }

  Future<void> wipe(ProviderContainer scope) async {
    final database = scope.read(appDatabaseProvider);
    await database.delete(database.maintenanceRecords).go();
    await database.delete(database.vehicleMaintenanceSettings).go();
    await database.delete(database.receiptAssets).go();
    await database.delete(database.vehicles).go();
    await database.delete(database.appPreferences).go();
  }

  testWidgets('captures the registration wizard', (tester) async {
    final scope = container();
    addTearDown(scope.dispose);
    await wipe(scope);

    await tester.pumpWidget(app(scope));
    await settle(tester);
    await shoot(tester, '01-empty-home');

    await tester.tap(find.widgetWithText(FilledButton, '차량 등록'));
    await settle(tester, frames: 80);
    await shoot(tester, '02-wizard-body-style');

    await tester.tap(find.text('슈퍼카'));
    await settle(tester, frames: 80);
    await shoot(tester, '03-wizard-supercar');

    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester, frames: 60);
    await shoot(tester, '03b-wizard-paint');

    await tester.tap(find.bySemanticsLabel('레드').first);
    await settle(tester, frames: 80);
    await shoot(tester, '03c-wizard-paint-red');

    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '내 아반떼');
    await settle(tester);
    await shoot(tester, '04-wizard-name');

    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '47250');
    await settle(tester);
    await shoot(tester, '05-wizard-mileage');

    await tester.tap(find.widgetWithText(FilledButton, '다음'));
    await settle(tester);
    await shoot(tester, '06-wizard-details');

    await tester.tap(find.widgetWithText(FilledButton, '차고에 넣기'));
    await settle(tester, frames: 100);
    await shoot(tester, '07-home-with-car');
  });

  testWidgets('captures a garage with history', (tester) async {
    final scope = container();
    addTearDown(scope.dispose);
    await wipe(scope);

    final vehicles = scope.read(vehicleRepositoryProvider);
    final maintenance = scope.read(maintenanceRepositoryProvider);
    final vehicleId = await vehicles.create(
      displayName: '내 아반떼',
      currentMileage: 47250,
      bodyStyle: 'sedan',
      paintColor: 'navy',
      manufacturer: '현대',
      model: '아반떼 CN7',
      modelYear: 2021,
    );
    final types = await maintenance.watchTypes().first;
    int idOf(String name) => types.firstWhere((t) => t.name == name).id;

    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: idOf('엔진오일'),
      maintenanceDate: DateTime.now().subtract(const Duration(days: 300)),
      mileage: 32000,
      cost: 82000,
      shopName: '동네카센터',
    );
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: idOf('에어컨필터'),
      maintenanceDate: DateTime.now().subtract(const Duration(days: 40)),
      mileage: 45000,
      cost: 18000,
    );
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: idOf('타이어'),
      maintenanceDate: DateTime.now().subtract(const Duration(days: 120)),
      mileage: 40000,
      cost: 480000,
      shopName: '타이어뱅크',
    );

    await tester.pumpWidget(app(scope));
    await settle(tester, frames: 100);
    await shoot(tester, '10-home-populated');

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);
    await shoot(tester, '11-records');

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    await shoot(tester, '12-settings');

    // 다크 테마로 바꾼 뒤 같은 화면들을 다시 찍는다.
    await tester.tap(find.widgetWithText(ListTile, '화면 테마'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, '다크'));
    await settle(tester, frames: 60);
    await shoot(tester, '13-settings-dark');

    await tester.tap(find.byIcon(Icons.home_outlined));
    await settle(tester, frames: 100);
    await shoot(tester, '14-home-dark');

    await wipe(scope);
  });
}
