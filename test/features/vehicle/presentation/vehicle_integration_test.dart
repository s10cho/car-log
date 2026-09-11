import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  group('the stale mileage nudge', () {
    testWidgets('is absent for a reading taken today', (tester) async {
      final (:app, :container) = buildTestApp();
      await container
          .read(vehicleRepositoryProvider)
          .create(displayName: '아반떼', currentMileage: 32000);

      await tester.pumpWidget(app);
      await settle(tester);

      expect(find.textContaining('주행거리를 업데이트하면'), findsNothing);
    });

    testWidgets('appears once the reading is old', (tester) async {
      final (:app, :container) = buildTestApp();
      await container
          .read(vehicleRepositoryProvider)
          .create(
            displayName: '아반떼',
            currentMileage: 32000,
            now: DateTime.now().subtract(const Duration(days: 60)),
          );

      await tester.pumpWidget(app);
      await settle(tester);

      expect(find.textContaining('주행거리를 업데이트하면'), findsOneWidget);
    });

    testWidgets('goes away after the user updates the odometer', (
      tester,
    ) async {
      final (:app, :container) = buildTestApp();
      await container
          .read(vehicleRepositoryProvider)
          .create(
            displayName: '아반떼',
            currentMileage: 32000,
            now: DateTime.now().subtract(const Duration(days: 60)),
          );

      await tester.pumpWidget(app);
      await settle(tester);
      await tester.tap(find.text('수정'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).last, '34000');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await settle(tester);

      expect(find.text('34,000 km'), findsOneWidget);
      expect(find.textContaining('주행거리를 업데이트하면'), findsNothing);
    });
  });

  group('the integration screen', () {
    testWidgets('says plainly that nothing is connected and why', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp().app);
      await settle(tester);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await settle(tester);
      await tester.tap(find.widgetWithText(ListTile, '차량 연동'));
      await settle(tester);

      expect(find.text('연동되지 않음'), findsOneWidget);
      expect(find.textContaining('비밀 키를 요구합니다'), findsOneWidget);
      // 지키지 못할 약속을 하지 않는다.
      expect(find.textContaining('곧 지원'), findsNothing);
      expect(find.textContaining('준비 중'), findsNothing);
    });
  });
}
