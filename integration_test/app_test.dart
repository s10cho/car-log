import 'package:car_log/app/app.dart';
import 'package:car_log/app/config/app_config.dart';
import 'package:car_log/core/database/database_providers.dart';
import 'package:car_log/features/maintenance/presentation/add_maintenance_page.dart';
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

  /// A container backed by the real on-device database file, so that a second
  /// container in the same test sees what the first one wrote — the same thing
  /// that happens when the app is killed and relaunched.
  ProviderContainer container() => ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(config)],
  );

  Widget app(ProviderContainer scope) =>
      UncontrolledProviderScope(container: scope, child: const CarLogApp());

  Future<void> settle(WidgetTester tester, {int frames = 20}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Leaves no rows behind between runs; the database file is shared with the
  /// device, not created fresh per test.
  Future<void> wipe(ProviderContainer scope) async {
    final database = scope.read(appDatabaseProvider);
    await database.delete(database.maintenanceRecords).go();
    await database.delete(database.vehicleMaintenanceSettings).go();
    await database.delete(database.vehicles).go();
  }

  testWidgets('first run: register a vehicle, record 엔진오일, see the next due', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);
    await wipe(scope);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    // 첫 실행 — 등록된 차량이 없다.
    expect(find.text('아직 등록된 차량이 없습니다'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '차량 등록'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '차량 이름'),
      '내 아반떼',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 주행거리 (km)'),
      '32000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('내 아반떼'), findsOneWidget);
    expect(find.text('32,000 km'), findsOneWidget);
    expect(find.text('아직 기록이 없어 다음 교체 시기를 계산할 수 없습니다.'), findsOneWidget);

    // 엔진오일 교체를 기록한다.
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '33000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.byType(AddMaintenancePage), findsNothing);
    // 33,000 + 10,000 km 기본 주기.
    expect(find.text('43,000 km'), findsOneWidget);
    expect(find.text('33,000 km'), findsWidgets);
  });

  testWidgets('the data is still there after a restart', (tester) async {
    // 앞 테스트가 남긴 데이터를 그대로 다시 연다.
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    expect(find.text('내 아반떼'), findsOneWidget);
    expect(find.text('43,000 km'), findsOneWidget);

    // 기록 탭에도 같은 기록이 보인다.
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);
    expect(find.text('정비 기록이 없습니다'), findsNothing);
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('changing the interval recalculates the due point', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    await tester.tap(find.textContaining('교체주기'));
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '주행거리 기준 (km)'),
      '5000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('38,000 km'), findsOneWidget);

    await wipe(scope);
  });
}
