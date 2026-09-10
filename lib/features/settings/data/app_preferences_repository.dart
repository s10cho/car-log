import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_exception.dart';

/// Reads and writes the app-level key/value preferences stored in Drift.
class AppPreferencesRepository {
  const AppPreferencesRepository(this._database);

  final AppDatabase _database;

  Future<String?> read(String key) async {
    try {
      final row = await (_database.select(
        _database.appPreferences,
      )..where((row) => row.key.equals(key))).getSingleOrNull();
      return row?.value;
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to read preference "$key"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Emits the current value and every later change to it.
  Stream<String?> watch(String key) {
    return (_database.select(_database.appPreferences)
          ..where((row) => row.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> write(String key, String value) async {
    try {
      await _database
          .into(_database.appPreferences)
          .insertOnConflictUpdate(
            AppPreferencesCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now(),
            ),
          );
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to write preference "$key"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> remove(String key) async {
    try {
      await (_database.delete(
        _database.appPreferences,
      )..where((row) => row.key.equals(key))).go();
    } on Object catch (error, stackTrace) {
      throw LocalDatabaseException(
        'Failed to delete preference "$key"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>(
  (ref) => AppPreferencesRepository(ref.watch(appDatabaseProvider)),
);
