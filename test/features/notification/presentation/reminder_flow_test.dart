import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/maintenance/presentation/maintenance_detail_page.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  /// A vehicle with one 엔진오일 record, which gives it a due date to remind on.
  Future<ProviderContainer> vehicleWithRecord(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '내 아반떼', currentMileage: 32000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime.now().subtract(const Duration(days: 30)),
      mileage: 31000,
    );

    await tester.pumpWidget(app);
    await settle(tester);
    return container;
  }

  Future<void> openReminderSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, '알림'));
    await settle(tester);
  }

  group('turning reminders on', () {
    testWidgets('is off to begin with and schedules nothing', (tester) async {
      final container = await vehicleWithRecord(tester);

      expect(notificationsOf(container).lastPlan, isEmpty);

      await openReminderSettings(tester);
      final toggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, '정비 알림'),
      );
      expect(toggle.value, isFalse);
    });

    testWidgets('asks for permission only when switched on', (tester) async {
      final container = await vehicleWithRecord(tester);
      await openReminderSettings(tester);

      expect(notificationsOf(container).permissionRequests, 0);

      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);

      expect(notificationsOf(container).permissionRequests, 1);
    });

    testWidgets('schedules a reminder once permission is granted', (
      tester,
    ) async {
      final container = await vehicleWithRecord(tester);
      await openReminderSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);

      final plan = notificationsOf(container).lastPlan;
      expect(plan, hasLength(1));
      expect(plan.single.typeName, '엔진오일');
      expect(plan.single.vehicleName, '내 아반떼');
    });

    testWidgets('stays off and explains when permission is refused', (
      tester,
    ) async {
      final container = await vehicleWithRecord(tester);
      notificationsOf(container).permissionGranted = false;
      await openReminderSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);

      expect(find.text('기기 설정에서 알림을 허용해야 알려 드릴 수 있습니다.'), findsOneWidget);
      final toggle = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, '정비 알림'),
      );
      expect(toggle.value, isFalse);
      expect(notificationsOf(container).lastPlan, isEmpty);
    });

    testWidgets('switching reminders back off clears the plan', (tester) async {
      final container = await vehicleWithRecord(tester);
      await openReminderSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);
      expect(notificationsOf(container).lastPlan, hasLength(1));

      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);

      expect(notificationsOf(container).lastPlan, isEmpty);
    });

    testWidgets('changing the lead time moves the reminder', (tester) async {
      final container = await vehicleWithRecord(tester);
      await openReminderSettings(tester);
      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);
      final before = notificationsOf(container).lastPlan.single.when;

      await tester.tap(find.text('7일 전').last);
      await settle(tester);
      await tester.tap(find.text('30일 전').last);
      await settle(tester);

      final after = notificationsOf(container).lastPlan.single.when;
      expect(after.isBefore(before), isTrue);
    });
  });

  group('per-item mute', () {
    testWidgets('muting an item drops it from the plan', (tester) async {
      final container = await vehicleWithRecord(tester);
      await openReminderSettings(tester);
      await tester.tap(find.widgetWithText(SwitchListTile, '정비 알림'));
      await settle(tester);
      expect(notificationsOf(container).lastPlan, hasLength(1));

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.home_outlined));
      await settle(tester);
      await tester.tap(find.text('엔진오일').first);
      await settle(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, '이 항목 알림'));
      await settle(tester);

      expect(notificationsOf(container).lastPlan, isEmpty);
    });
  });

  group('tapping a notification', () {
    testWidgets('opens the maintenance detail for that item', (tester) async {
      final container = await vehicleWithRecord(tester);
      final typeId =
          (await container.read(maintenanceRepositoryProvider).engineOilType())
              .id;

      notificationsOf(container).tap('1:$typeId');
      await settle(tester);

      expect(find.byType(MaintenanceDetailPage), findsOneWidget);
      expect(find.text('이 항목의 기록'), findsOneWidget);
    });

    testWidgets('ignores a payload it cannot read', (tester) async {
      final container = await vehicleWithRecord(tester);

      notificationsOf(container).tap('쓰레기');
      await settle(tester);

      expect(find.byType(MaintenanceDetailPage), findsNothing);
    });
  });
}
