import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  Future<ProviderContainer> openTypes(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, '항목 관리'));
    await settle(tester);

    return container;
  }

  testWidgets('lists the built-in catalogue with its intervals', (
    tester,
  ) async {
    await openTypes(tester);

    expect(find.text('엔진오일'), findsOneWidget);
    expect(find.text('와이퍼'), findsOneWidget);
    // 엔진오일과 오일필터가 같은 주기를 쓰므로 행을 지정해서 본다.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('엔진오일'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('10,000 km 또는 12개월'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('와이퍼'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('12개월'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('adds a custom item', (tester) async {
    await openTypes(tester);

    await tester.tap(find.byTooltip('항목 추가'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, '항목 이름'),
      '하부 코팅',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '기간 기준'), '24');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    // 새 항목은 목록 맨 아래에 붙으므로 스크롤해야 보인다.
    await tester.scrollUntilVisible(find.text('하부 코팅'), 200);
    expect(find.text('하부 코팅'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('하부 코팅'),
          matching: find.byType(ListTile),
        ),
        matching: find.text('24개월'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('refuses an item with no interval at all', (tester) async {
    await openTypes(tester);

    await tester.tap(find.byTooltip('항목 추가'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '항목 이름'), '뭔가');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('주행거리와 기간 중 하나는 입력해 주세요'), findsWidgets);
  });

  testWidgets('edits a built-in interval', (tester) async {
    await openTypes(tester);

    final wiperRow = find.ancestor(
      of: find.text('와이퍼'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: wiperRow, matching: find.byIcon(Icons.edit_outlined)),
    );
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '기간 기준'), '6');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    expect(find.text('6개월'), findsOneWidget);
  });

  testWidgets('built-in items cannot be deleted', (tester) async {
    await openTypes(tester);

    final engineOilRow = find.ancestor(
      of: find.text('엔진오일'),
      matching: find.byType(ListTile),
    );

    expect(
      find.descendant(
        of: engineOilRow,
        matching: find.byIcon(Icons.delete_outline),
      ),
      findsNothing,
    );
  });

  testWidgets('a custom item in use cannot be deleted', (tester) async {
    final container = await openTypes(tester);
    final maintenance = container.read(maintenanceRepositoryProvider);
    final typeId = await maintenance.createCustomType(
      name: '하부 코팅',
      timeIntervalMonths: 24,
    );
    await maintenance.addRecord(
      vehicleId: 1,
      maintenanceTypeId: typeId,
      maintenanceDate: DateTime(2026, 1, 1),
      mileage: 31000,
    );
    await settle(tester);

    await tester.scrollUntilVisible(find.text('하부 코팅'), 200);
    final row = find.ancestor(
      of: find.text('하부 코팅'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)),
    );
    await settle(tester);

    expect(find.textContaining('정비 기록이 1건 있습니다'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '확인'));
    await settle(tester);
    expect(find.text('하부 코팅'), findsOneWidget);
  });

  testWidgets('an unused custom item is deleted after confirmation', (
    tester,
  ) async {
    final container = await openTypes(tester);
    await container
        .read(maintenanceRepositoryProvider)
        .createCustomType(name: '하부 코팅', timeIntervalMonths: 24);
    await settle(tester);

    await tester.scrollUntilVisible(find.text('하부 코팅'), 200);
    final row = find.ancestor(
      of: find.text('하부 코팅'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)),
    );
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await settle(tester);

    expect(find.text('하부 코팅'), findsNothing);
  });
}
