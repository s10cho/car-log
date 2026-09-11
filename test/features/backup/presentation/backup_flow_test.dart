import 'dart:convert';
import 'dart:io';

import 'package:car_log/features/backup/data/backup_repository.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../support/fake_receipt_picker.dart';
import '../../../support/test_app.dart';

void main() {
  Future<ProviderContainer> openBackup(WidgetTester tester) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, '백업 / 복원'));
    await settle(tester);
    return container;
  }

  /// Writes a backup file the file picker will hand back.
  Future<File> backupFileFrom(ProviderContainer container) async {
    final document = await container
        .read(backupRepositoryProvider)
        .buildBackup(appVersion: '1.0.0+1');
    final directory = Directory.systemTemp.createTempSync('car_log_backup');
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    return File(p.join(directory.path, 'backup.json'))
      ..writeAsStringSync(jsonEncode(document.toJson()));
  }

  testWidgets('says what a backup does and does not carry', (tester) async {
    await openBackup(tester);

    expect(find.text('백업 내보내기'), findsOneWidget);
    expect(find.text('백업 복원하기'), findsOneWidget);
    expect(find.textContaining('영수증 사진은 들어가지 않습니다'), findsOneWidget);
    expect(find.textContaining('AI API 키'), findsOneWidget);
  });

  testWidgets('importing asks before replacing anything', (tester) async {
    final container = await openBackup(tester);
    final file = await backupFileFrom(container);

    // 복원 전에 차를 하나 더 만든다. 확인 창을 취소하면 그대로 남아야 한다.
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '나중에 산 차', currentMileage: 10);

    pickerOf(container).next = FakeReceiptPicker.fileFor(file);
    await tapAndAwaitIo(tester, find.widgetWithText(ListTile, '백업 복원하기'));

    expect(find.text('이 백업으로 되돌릴까요?'), findsOneWidget);
    expect(find.textContaining('차량 1대'), findsOneWidget);
    expect(find.textContaining('되돌릴 수 없습니다'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await settle(tester);

    expect(await readVehicles(container), hasLength(2));
  });

  testWidgets('confirming replaces the data', (tester) async {
    final container = await openBackup(tester);
    final file = await backupFileFrom(container);
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '나중에 산 차', currentMileage: 10);

    pickerOf(container).next = FakeReceiptPicker.fileFor(file);
    await tapAndAwaitIo(tester, find.widgetWithText(ListTile, '백업 복원하기'));
    await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '복원'));

    expect(find.text('백업을 복원했습니다.'), findsOneWidget);
    expect((await readVehicles(container)).map((v) => v.displayName), ['아반떼']);
  });

  testWidgets('a file that is not a backup is refused', (tester) async {
    final container = await openBackup(tester);
    final directory = Directory.systemTemp.createTempSync('car_log_junk');
    addTearDown(() => directory.deleteSync(recursive: true));
    final junk = File(p.join(directory.path, 'photo.json'))
      ..writeAsStringSync('{"hello":"world"}');

    pickerOf(container).next = FakeReceiptPicker.fileFor(junk);
    await tapAndAwaitIo(tester, find.widgetWithText(ListTile, '백업 복원하기'));

    expect(find.text('백업 파일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('이 백업으로 되돌릴까요?'), findsNothing);
  });

  testWidgets('unreadable contents are refused rather than half-imported', (
    tester,
  ) async {
    final container = await openBackup(tester);
    final directory = Directory.systemTemp.createTempSync('car_log_junk');
    addTearDown(() => directory.deleteSync(recursive: true));
    final junk = File(p.join(directory.path, 'notjson.json'))
      ..writeAsStringSync('이건 JSON 이 아닙니다');

    pickerOf(container).next = FakeReceiptPicker.fileFor(junk);
    await tapAndAwaitIo(tester, find.widgetWithText(ListTile, '백업 복원하기'));

    expect(find.text('백업 파일을 읽지 못했습니다.'), findsOneWidget);
  });

  testWidgets('backing out of the file picker does nothing', (tester) async {
    final container = await openBackup(tester);
    pickerOf(container).next = null;

    await tapAndAwaitIo(tester, find.widgetWithText(ListTile, '백업 복원하기'));

    expect(find.text('이 백업으로 되돌릴까요?'), findsNothing);
    expect(await readMaintenanceTypes(container), isNotEmpty);
  });
}
