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

  /// Route transitions and the first database read take longer on a device
  /// than in a widget test, so this pumps generously.
  Future<void> settle(WidgetTester tester, {int frames = 40}) async {
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
    await (database.delete(
      database.maintenanceTypes,
    )..where((t) => t.isBuiltIn.equals(false))).go();
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
    expect(find.text('정비를 기록하면 다음 교체 시기를 여기에서 확인할 수 있습니다.'), findsOneWidget);

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
  });

  testWidgets('a second vehicle keeps its own odometer and records', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    // 차량 선택기 → 차량 추가.
    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, '차량 추가'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '차량 이름'), '카니발');
    await tester.enterText(
      find.widgetWithText(TextFormField, '현재 주행거리 (km)'),
      '12000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // 새 차량이 선택되어 있고, 기록은 비어 있다.
    expect(find.text('카니발'), findsOneWidget);
    expect(find.text('12,000 km'), findsOneWidget);
    expect(find.text('정비를 기록하면 다음 교체 시기를 여기에서 확인할 수 있습니다.'), findsOneWidget);

    // 아반떼로 되돌리면 그 차의 상태가 그대로 보인다.
    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
    await tester.tap(find.text('내 아반떼'));
    await settle(tester);

    expect(find.text('33,000 km'), findsWidgets);
    expect(find.text('38,000 km'), findsOneWidget);
  });

  testWidgets('deleting a vehicle takes its records with it', (tester) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.expand_more));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.adaptive.more).first);
    await settle(tester);
    await tester.tap(find.text('삭제'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // 남은 차량은 카니발 하나.
    expect(find.text('카니발'), findsOneWidget);
    expect(find.text('내 아반떼'), findsNothing);
  });

  testWidgets('a custom maintenance item can be added and recorded', (
    tester,
  ) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    // 항목 관리 → 새 항목 추가.
    await tester.tap(find.widgetWithText(TextButton, '항목 관리'));
    await settle(tester);
    await tester.tap(find.byTooltip('항목 추가'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '항목 이름'),
      '하부 코팅',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '기간 기준'), '24');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // 그 항목으로 기록을 남긴다.
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.tap(find.text('엔진오일'));
    await settle(tester);
    await tester.tap(find.text('하부 코팅').last);
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '12500',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    // 홈에 새 항목이 상태 카드로 올라온다.
    expect(find.text('하부 코팅'), findsWidgets);
    expect(find.text('교체주기 24개월'), findsOneWidget);
  });

  testWidgets('a status card opens the maintenance detail', (tester) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    await tester.tap(find.text('하부 코팅').first);
    await settle(tester);

    expect(find.text('이 항목의 기록'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, '이 항목 알림'), findsOneWidget);
  });

  testWidgets('reminders start switched off', (tester) async {
    final scope = container();
    addTearDown(scope.dispose);

    await tester.pumpWidget(app(scope));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, '알림'));
    await settle(tester);

    // 실기기 권한 창을 띄우지 않도록 켜 보지는 않는다. 기본값이 꺼짐인지만 본다.
    final toggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, '정비 알림'),
    );
    expect(toggle.value, isFalse);

    await wipe(scope);
  });
}
