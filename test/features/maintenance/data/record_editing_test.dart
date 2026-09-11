import 'dart:io';

import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/receipt/data/receipt_storage.dart';
import 'package:car_log/features/receipt/domain/picked_receipt.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late ReceiptStorage storage;
  late MaintenanceRepository maintenance;
  late VehicleRepository vehicles;
  late int vehicleId;
  late int engineOil;
  late int wiper;

  setUp(() async {
    database = openTestDatabase();
    storage = openTestReceiptStorage(database);
    maintenance = openTestMaintenanceRepository(database);
    vehicles = openTestVehicleRepository(database);
    vehicleId = await vehicles.create(
      displayName: '아반떼',
      currentMileage: 32000,
      now: DateTime(2026, 1, 1),
    );
    final types = await maintenance.watchTypes().first;
    engineOil = types.firstWhere((t) => t.name == '엔진오일').id;
    wiper = types.firstWhere((t) => t.name == '와이퍼').id;
  });

  PickedReceipt pick(String name, [String contents = 'receipt']) {
    final directory = Directory.systemTemp.createTempSync('car_log_pick');
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final file = File(p.join(directory.path, name))
      ..writeAsStringSync(contents);
    return PickedReceipt(
      file: file,
      fileName: name,
      mimeType: mimeTypeForExtension(p.extension(name)),
    );
  }

  Future<int> addRecord({PickedReceipt? receipt, int mileage = 33000}) =>
      maintenance.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOil,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: mileage,
        cost: 80000,
        shopName: '동네카센터',
        receipt: receipt,
      );

  Future<void> edit(
    int id, {
    int? typeId,
    DateTime? date,
    int mileage = 33000,
    int? cost,
    String? shopName,
    String? memo,
    PickedReceipt? receipt,
    bool removeReceipt = false,
  }) => maintenance.updateRecord(
    recordId: id,
    maintenanceTypeId: typeId ?? engineOil,
    maintenanceDate: date ?? DateTime(2026, 2, 1),
    mileage: mileage,
    cost: cost,
    shopName: shopName,
    memo: memo,
    receipt: receipt,
    removeReceipt: removeReceipt,
  );

  group('editing the fields', () {
    test('changes what it is told to change', () async {
      final id = await addRecord();

      await edit(
        id,
        typeId: wiper,
        date: DateTime(2026, 3, 5),
        mileage: 34000,
        cost: 25000,
        shopName: '오토큐',
        memo: '앞유리만',
      );

      final record = (await maintenance.findRecord(id))!;
      expect(record.maintenanceTypeId, wiper);
      expect(record.maintenanceDate, DateTime(2026, 3, 5));
      expect(record.mileage, 34000);
      expect(record.cost, 25000);
      expect(record.shopName, '오토큐');
      expect(record.memo, '앞유리만');
    });

    test('clears an optional field that is left out', () async {
      final id = await addRecord();

      await edit(id);

      final record = (await maintenance.findRecord(id))!;
      expect(record.cost, isNull);
      expect(record.shopName, isNull);
    });

    test('a corrected higher reading moves the odometer forward', () async {
      final id = await addRecord(mileage: 33000);

      await edit(id, mileage: 36000);

      expect((await vehicles.findById(vehicleId))!.currentMileage, 36000);
    });

    test('a corrected lower reading leaves the odometer alone', () async {
      final id = await addRecord(mileage: 36000);
      expect((await vehicles.findById(vehicleId))!.currentMileage, 36000);

      await edit(id, mileage: 33000);

      expect((await vehicles.findById(vehicleId))!.currentMileage, 36000);
    });

    test('editing a record that is gone is refused', () async {
      final id = await addRecord();
      await maintenance.deleteRecord(id);

      expect(() => edit(id), throwsA(isA<Exception>()));
    });
  });

  group('the receipt', () {
    test('is left alone by an edit that says nothing about it', () async {
      final id = await addRecord(receipt: pick('receipt.jpg', '원본'));
      final before = await maintenance.receiptFor(id);

      await edit(id, mileage: 34000);

      final after = await maintenance.receiptFor(id);
      expect(after!.id, before!.id);
      expect(
        (await storage.resolve(after.relativePath)).readAsStringSync(),
        '원본',
      );
    });

    test('can be attached to a record that had none', () async {
      final id = await addRecord();

      await edit(id, receipt: pick('new.jpg', '새 영수증'));

      final asset = await maintenance.receiptFor(id);
      expect(asset!.fileName, 'new.jpg');
      expect(
        (await storage.resolve(asset.relativePath)).readAsStringSync(),
        '새 영수증',
      );
    });

    test('replacing one deletes the old file', () async {
      final id = await addRecord(receipt: pick('old.jpg', '옛것'));
      final old = await maintenance.receiptFor(id);
      final oldFile = await storage.resolve(old!.relativePath);

      await edit(id, receipt: pick('new.jpg', '새것'));

      expect(oldFile.existsSync(), isFalse);
      final current = await maintenance.receiptFor(id);
      expect(current!.fileName, 'new.jpg');
    });

    test('removing one deletes the file and unlinks the record', () async {
      final id = await addRecord(receipt: pick('receipt.jpg'));
      final asset = await maintenance.receiptFor(id);
      final file = await storage.resolve(asset!.relativePath);

      await edit(id, removeReceipt: true);

      expect(file.existsSync(), isFalse);
      expect(await maintenance.receiptFor(id), isNull);
    });

    test('no orphan asset row is left behind', () async {
      final id = await addRecord(receipt: pick('receipt.jpg'));

      await edit(id, removeReceipt: true);

      expect(await database.select(database.receiptAssets).get(), isEmpty);
    });
  });

  group('deleting a record', () {
    test('removes it from the list', () async {
      final id = await addRecord();

      await maintenance.deleteRecord(id);

      expect(await maintenance.findRecord(id), isNull);
      expect(await maintenance.watchRecords(vehicleId).first, isEmpty);
    });

    test('takes its receipt file with it', () async {
      final id = await addRecord(receipt: pick('receipt.jpg'));
      final asset = await maintenance.receiptFor(id);
      final file = await storage.resolve(asset!.relativePath);

      await maintenance.deleteRecord(id);

      expect(file.existsSync(), isFalse);
      expect(await database.select(database.receiptAssets).get(), isEmpty);
    });

    test('leaves other records alone', () async {
      final kept = await addRecord(mileage: 33000);
      final gone = await addRecord(mileage: 34000);

      await maintenance.deleteRecord(gone);

      expect(await maintenance.findRecord(kept), isNotNull);
    });

    test('the next due point falls back to the previous record', () async {
      final older = await maintenance.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOil,
        maintenanceDate: DateTime(2025, 8, 1),
        mileage: 25000,
      );
      final newer = await maintenance.addRecord(
        vehicleId: vehicleId,
        maintenanceTypeId: engineOil,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 33000,
      );
      expect(older, isNot(newer));

      await maintenance.deleteRecord(newer);

      final statuses = await maintenance
          .watchStatuses(vehicleId: vehicleId)
          .first;
      final oil = statuses.firstWhere((s) => s.typeId == engineOil);
      expect(oil.lastServiceMileage, 25000);
      expect(oil.due!.dueMileage, 35000);
    });
  });
}
