import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  testWidgets('shows the empty state when nothing has been recorded', (
    tester,
  ) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);

    expect(find.text('정비 기록이 없습니다'), findsOneWidget);
  });

  testWidgets('lists every record, most recent first', (tester) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 40000);
    final typeId = (await maintenance.engineOilType()).id;

    for (final (date, mileage) in [
      (DateTime(2025, 3, 1), 20000),
      (DateTime(2026, 3, 1), 35000),
      (DateTime(2025, 9, 1), 27000),
    ]) {
      await maintenance.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: typeId,
        maintenanceDate: date,
        mileage: mileage,
      );
    }

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);

    final dates = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListTile),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .whereType<String>()
        .where((text) => text.startsWith('202'))
        .toList();

    expect(dates, ['2026.03.01', '2025.09.01', '2025.03.01']);
  });
}
