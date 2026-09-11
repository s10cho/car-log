import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/receipt/domain/picked_receipt.dart';
import 'package:car_log/features/receipt/presentation/receipt_view.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_receipt_picker.dart';
import '../../../support/test_app.dart';

void main() {
  Future<ProviderContainer> openRecordForm(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    return container;
  }

  Future<void> attach(WidgetTester tester, String option) async {
    await tester.tap(find.widgetWithText(OutlinedButton, '영수증 첨부'));
    await settle(tester);
    await tester.tap(find.text(option));
    await settle(tester);
  }

  testWidgets('offers camera, gallery and file', (tester) async {
    await openRecordForm(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, '영수증 첨부'));
    await settle(tester);

    expect(find.text('촬영'), findsOneWidget);
    expect(find.text('앨범에서 선택'), findsOneWidget);
    expect(find.text('파일에서 선택'), findsOneWidget);
  });

  testWidgets('each option asks the picker for that source', (tester) async {
    final container = await openRecordForm(tester);
    final picker = pickerOf(container);
    picker.next = FakeReceiptPicker.fileNamed('receipt.jpg');

    await attach(tester, '촬영');
    expect(picker.requested.last, ReceiptSource.camera);

    await tester.tap(find.byTooltip('첨부 취소'));
    await settle(tester);
    await attach(tester, '파일에서 선택');
    expect(picker.requested.last, ReceiptSource.file);
  });

  testWidgets('shows the chosen file before saving', (tester) async {
    final container = await openRecordForm(tester);
    pickerOf(container).next = FakeReceiptPicker.fileNamed('영수증.jpg');

    await attach(tester, '앨범에서 선택');

    expect(find.text('영수증.jpg'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsNothing);
  });

  testWidgets('backing out of the picker attaches nothing', (tester) async {
    final container = await openRecordForm(tester);
    pickerOf(container).next = null;

    await attach(tester, '촬영');

    expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsOneWidget);
  });

  testWidgets('a picker failure is reported and leaves the form usable', (
    tester,
  ) async {
    final container = await openRecordForm(tester);
    pickerOf(container).error = StateError('camera unavailable');

    await attach(tester, '촬영');

    expect(find.text('영수증을 불러오지 못했습니다.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsOneWidget);
  });

  testWidgets('clearing the attachment goes back to the empty slot', (
    tester,
  ) async {
    final container = await openRecordForm(tester);
    pickerOf(container).next = FakeReceiptPicker.fileNamed('receipt.jpg');
    await attach(tester, '촬영');

    await tester.tap(find.byTooltip('첨부 취소'));
    await settle(tester);

    expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsOneWidget);
  });

  testWidgets('a saved receipt can be opened from the maintenance detail', (
    tester,
  ) async {
    final container = await openRecordForm(tester);
    pickerOf(container).next = FakeReceiptPicker.fileNamed('영수증.jpg');

    await attach(tester, '앨범에서 선택');
    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '33000',
    );
    await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));

    // 홈 → 정비 상세 → 영수증. 상태 카드를 눌러야 한다.
    await tester.tap(
      find.descendant(of: find.byType(Card), matching: find.text('엔진오일')),
    );
    await settle(tester);
    expect(find.text('이 항목의 기록'), findsOneWidget);
    expect(find.byTooltip('영수증 보기'), findsOneWidget);

    await tester.tap(find.byTooltip('영수증 보기'));
    await settle(tester);

    expect(find.byType(ReceiptViewPage), findsOneWidget);
    expect(find.text('영수증.jpg'), findsWidgets);
  });

  testWidgets('a record saved without a receipt offers nothing to open', (
    tester,
  ) async {
    final container = await openRecordForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
      '33000',
    );
    await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));
    await tester.tap(
      find.descendant(of: find.byType(Card), matching: find.text('엔진오일')),
    );
    await settle(tester);

    expect(find.text('이 항목의 기록'), findsOneWidget);
    expect(find.byTooltip('영수증 보기'), findsNothing);
    expect(
      container.read(maintenanceRepositoryProvider),
      isA<MaintenanceRepository>(),
    );
  });
}
