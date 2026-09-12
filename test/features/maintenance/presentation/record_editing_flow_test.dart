import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_receipt_picker.dart';
import '../../../support/test_app.dart';

void main() {
  /// A vehicle with one 엔진오일 record, opened on the 기록 tab.
  Future<ProviderContainer> openRecordList(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    final maintenance = container.read(maintenanceRepositoryProvider);
    final vehicleId = await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 33000);
    await maintenance.addRecord(
      vehicleId: vehicleId,
      maintenanceTypeId: (await maintenance.engineOilType()).id,
      maintenanceDate: DateTime(2026, 2, 1),
      mileage: 33000,
      cost: 80000,
      shopName: '동네카센터',
    );

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await settle(tester);
    return container;
  }

  Future<void> openRecord(WidgetTester tester) async {
    await tester.tap(find.byType(ListTile).first);
    await settle(tester);
  }

  testWidgets('tapping a record opens it filled in', (tester) async {
    await openRecordList(tester);
    await openRecord(tester);

    expect(find.text('기록 수정'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
          )
          .controller
          ?.text,
      '33000',
    );
    expect(find.text('2026.02.01'), findsOneWidget);
  });

  testWidgets('saving an edit updates the record', (tester) async {
    final container = await openRecordList(tester);
    await openRecord(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '34500',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '정비소'), '오토큐');
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);

    final record = await container
        .read(maintenanceRepositoryProvider)
        .findRecord(1);
    expect(record!.mileage, 34500);
    expect(record.shopName, '오토큐');
    expect(find.text('34,500 km · 80,000원 · 오토큐'), findsOneWidget);
  });

  testWidgets('a corrected reading moves the odometer on the home screen', (
    tester,
  ) async {
    await openRecordList(tester);
    await openRecord(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '38000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await settleAnimations(tester);

    expect(find.text('38,000 km'), findsWidgets);
  });

  testWidgets('the delete action asks before removing', (tester) async {
    final container = await openRecordList(tester);
    await openRecord(tester);

    await tester.tap(find.byTooltip('기록 삭제'));
    await settle(tester);
    expect(find.text('첨부한 영수증도 함께 삭제됩니다. 되돌릴 수 없습니다.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await settle(tester);

    expect(
      await container.read(maintenanceRepositoryProvider).findRecord(1),
      isNotNull,
    );
  });

  testWidgets('confirming the delete removes the record', (tester) async {
    final container = await openRecordList(tester);
    await openRecord(tester);

    await tester.tap(find.byTooltip('기록 삭제'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await settle(tester);

    expect(
      await container.read(maintenanceRepositoryProvider).findRecord(1),
      isNull,
    );
    expect(find.text('정비 기록이 없습니다'), findsOneWidget);
  });

  testWidgets('adding a record still says 정비 기록, not 기록 수정', (tester) async {
    await openRecordList(tester);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    expect(find.text('정비 기록'), findsOneWidget);
    expect(find.byTooltip('기록 삭제'), findsNothing);
  });

  group('the attached receipt', () {
    testWidgets('is shown and can be replaced', (tester) async {
      final container = await openRecordList(tester);
      pickerOf(container).next = FakeReceiptPicker.fileNamed('새영수증.jpg');
      await openRecord(tester);

      // 붙어 있는 게 없으므로 첨부 버튼이 보인다.
      expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '영수증 첨부'));
      await settle(tester);
      await tester.tap(find.text('앨범에서 선택'));
      await settle(tester);
      await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));

      final asset = await container
          .read(maintenanceRepositoryProvider)
          .receiptFor(1);
      expect(asset!.fileName, '새영수증.jpg');
    });

    testWidgets('an existing one shows with 교체 and 첨부 삭제', (tester) async {
      final container = await openRecordList(tester);
      pickerOf(container).next = FakeReceiptPicker.fileNamed('영수증.jpg');
      await openRecord(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, '영수증 첨부'));
      await settle(tester);
      await tester.tap(find.text('앨범에서 선택'));
      await settle(tester);
      await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));

      await openRecord(tester);

      expect(find.text('영수증.jpg'), findsOneWidget);
      expect(find.text('첨부됨'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '교체'), findsOneWidget);
      expect(find.byTooltip('첨부 삭제'), findsOneWidget);
    });

    testWidgets('removing it takes effect only on save', (tester) async {
      final container = await openRecordList(tester);
      final repository = container.read(maintenanceRepositoryProvider);
      pickerOf(container).next = FakeReceiptPicker.fileNamed('영수증.jpg');
      await openRecord(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, '영수증 첨부'));
      await settle(tester);
      await tester.tap(find.text('앨범에서 선택'));
      await settle(tester);
      await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));
      expect(await repository.receiptFor(1), isNotNull);

      await openRecord(tester);
      await tester.tap(find.byTooltip('첨부 삭제'));
      await settle(tester);
      expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsOneWidget);
      // 아직 저장 전이라 남아 있다.
      expect(await repository.receiptFor(1), isNotNull);

      await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));

      expect(await repository.receiptFor(1), isNull);
    });
  });
}
