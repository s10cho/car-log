import 'package:car_log/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens an in-memory [AppDatabase] that is closed when the test finishes.
AppDatabase openTestDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}
