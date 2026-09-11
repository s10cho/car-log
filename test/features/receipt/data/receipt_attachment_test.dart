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
  late int typeId;

  setUp(() async {
    database = openTestDatabase();
    storage = openTestReceiptStorage(database);
    maintenance = openTestMaintenanceRepository(database);
    vehicles = openTestVehicleRepository(database);
    vehicleId = await vehicles.create(
      displayName: '아반떼',
      currentMileage: 32000,
    );
    typeId = (await maintenance.engineOilType()).id;
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

  Future<int> addRecord({PickedReceipt? receipt}) => maintenance.addRecord(
    vehicleId: vehicleId,
    maintenanceTypeId: typeId,
    maintenanceDate: DateTime(2026, 2, 1),
    mileage: 33000,
    receipt: receipt,
  );

  test('a record without a receipt has none attached', () async {
    final id = await addRecord();

    expect(await maintenance.receiptFor(id), isNull);
  });

  test('an attached receipt is copied in and linked to the record', () async {
    final id = await addRecord(receipt: pick('receipt.jpg', '영수증'));

    final asset = await maintenance.receiptFor(id);
    expect(asset, isNotNull);
    expect(asset!.fileName, 'receipt.jpg');
    expect(asset.mimeType, 'image/jpeg');
    expect(
      (await storage.resolve(asset.relativePath)).readAsStringSync(),
      '영수증',
    );
  });

  test('a PDF receipt is stored with its own mime type', () async {
    final id = await addRecord(receipt: pick('receipt.pdf'));

    expect((await maintenance.receiptFor(id))!.mimeType, 'application/pdf');
  });

  test('the stored path is relative to the documents directory', () async {
    final id = await addRecord(receipt: pick('receipt.jpg'));

    final asset = await maintenance.receiptFor(id);
    expect(p.isRelative(asset!.relativePath), isTrue);
    expect(asset.relativePath, startsWith('$receiptsDirectoryName/'));
  });

  test('two records keep their own receipts', () async {
    final first = await addRecord(receipt: pick('a.jpg', 'first'));
    final second = await addRecord(receipt: pick('b.jpg', 'second'));

    final one = await maintenance.receiptFor(first);
    final two = await maintenance.receiptFor(second);
    expect(
      (await storage.resolve(one!.relativePath)).readAsStringSync(),
      'first',
    );
    expect(
      (await storage.resolve(two!.relativePath)).readAsStringSync(),
      'second',
    );
  });

  group('deleting a vehicle', () {
    test('removes the receipt files of its records', () async {
      final id = await addRecord(receipt: pick('receipt.jpg'));
      final asset = await maintenance.receiptFor(id);
      final file = await storage.resolve(asset!.relativePath);
      expect(file.existsSync(), isTrue);

      await vehicles.delete(vehicleId);

      expect(file.existsSync(), isFalse);
    });

    test('leaves another vehicle\'s receipts alone', () async {
      final other = await vehicles.create(
        displayName: '카니발',
        currentMileage: 100,
      );
      final keptId = await maintenance.addRecord(
        vehicleId: other,
        maintenanceTypeId: typeId,
        maintenanceDate: DateTime(2026, 2, 1),
        mileage: 200,
        receipt: pick('kept.jpg', 'kept'),
      );
      await addRecord(receipt: pick('gone.jpg'));

      await vehicles.delete(vehicleId);

      final kept = await maintenance.receiptFor(keptId);
      expect(
        (await storage.resolve(kept!.relativePath)).readAsStringSync(),
        'kept',
      );
    });
  });
}
