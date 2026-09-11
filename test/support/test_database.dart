import 'dart:io';

import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/maintenance/data/maintenance_repository.dart';
import 'package:car_log/features/receipt/data/receipt_storage.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens an in-memory [AppDatabase] that is closed when the test finishes.
AppDatabase openTestDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

/// One receipt storage per test database, so that repositories built over the
/// same database write and delete the same files.
final Expando<ReceiptStorage> _storages = Expando<ReceiptStorage>();

ReceiptStorage openTestReceiptStorage([AppDatabase? database]) {
  final existing = database == null ? null : _storages[database];
  if (existing != null) {
    return existing;
  }

  final documents = Directory.systemTemp.createTempSync('car_log_receipts');
  addTearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });
  final storage = ReceiptStorage(documentsDirectory: () async => documents);
  if (database != null) {
    _storages[database] = storage;
  }
  return storage;
}

/// A maintenance repository over an in-memory database and temporary storage.
MaintenanceRepository openTestMaintenanceRepository(AppDatabase database) =>
    MaintenanceRepository(database, openTestReceiptStorage(database));

/// A vehicle repository sharing that database's receipt storage.
VehicleRepository openTestVehicleRepository(AppDatabase database) =>
    VehicleRepository(database, openTestReceiptStorage(database));
