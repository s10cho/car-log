import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../ai/data/ai_credentials.dart';
import '../../receipt/data/receipt_storage.dart';
import '../domain/backup_document.dart';
import 'backup_mapping.dart';

/// Preference keys that must never leave the device inside a backup.
///
/// Not secrets themselves — the keys are in secure storage — but restoring a
/// pointer to a provider whose key is gone would leave the app looking
/// connected when it is not.
const Set<String> _excludedPreferenceKeys = {
  selectedAiProviderKey,
  aiConsentKey,
};

/// Exports and restores the user's data.
///
/// Credentials are never included: AI API keys and OAuth tokens live in secure
/// storage and stay there. A restored install asks the user to reconnect.
class BackupRepository {
  const BackupRepository(this._database, this._receipts);

  final AppDatabase _database;
  final ReceiptStorage _receipts;

  /// Builds a backup of everything the user owns.
  Future<BackupDocument> buildBackup({required String appVersion}) async {
    final vehicles = await _database.select(_database.vehicles).get();
    final types = await _database.select(_database.maintenanceTypes).get();
    final settings = await _database
        .select(_database.vehicleMaintenanceSettings)
        .get();
    final records = await _database.select(_database.maintenanceRecords).get();
    final preferences = await _database.select(_database.appPreferences).get();

    return BackupDocument(
      formatVersion: backupFormatVersion,
      exportedAt: DateTime.now(),
      appVersion: appVersion,
      vehicles: [for (final row in vehicles) vehicleToJson(row)],
      maintenanceTypes: [for (final row in types) maintenanceTypeToJson(row)],
      settings: [for (final row in settings) settingToJson(row)],
      // Receipt files are not carried: they would multiply the file size by
      // hundreds and a backup nobody can email is a backup nobody takes. The
      // records keep their other fields; only the attachment is dropped.
      records: [for (final row in records) recordToJson(row)],
      preferences: {
        for (final row in preferences)
          if (!_excludedPreferenceKeys.contains(row.key)) row.key: row.value,
      },
    );
  }

  /// Writes a backup to a file the user can move somewhere safe.
  Future<File> exportToFile({required String appVersion}) async {
    try {
      final document = await buildBackup(appVersion: appVersion);
      final directory = await getApplicationDocumentsDirectory();
      final stamp = document.exportedAt
          .toIso8601String()
          .substring(0, 19)
          .replaceAll(RegExp(r'[:\-]'), '');
      final file = File(p.join(directory.path, 'car-log-backup-$stamp.json'));

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(document.toJson()),
      );
      return file;
    } on Object catch (error, stackTrace) {
      throw BackupException(
        '백업 파일을 만들지 못했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Replaces everything with the contents of [document].
  ///
  /// All or nothing: a half-applied import would leave the user with a mixture
  /// of two devices' data and no way to tell which is which.
  Future<void> restore(BackupDocument document) async {
    try {
      await _database.transaction(() async {
        // Receipt files belong to records that are about to disappear.
        final assets = await _database.select(_database.receiptAssets).get();

        await _database.delete(_database.maintenanceRecords).go();
        await _database.delete(_database.vehicleMaintenanceSettings).go();
        await _database.delete(_database.receiptAssets).go();
        await _database.delete(_database.vehicles).go();
        await (_database.delete(
          _database.maintenanceTypes,
        )..where((t) => t.isBuiltIn.equals(false))).go();
        await _database.delete(_database.appPreferences).go();

        await _restoreTypes(document.maintenanceTypes);
        for (final row in document.vehicles) {
          await _database.into(_database.vehicles).insert(vehicleFromJson(row));
        }
        for (final row in document.settings) {
          await _database
              .into(_database.vehicleMaintenanceSettings)
              .insert(settingFromJson(row));
        }
        for (final row in document.records) {
          await _database
              .into(_database.maintenanceRecords)
              .insert(recordFromJson(row));
        }

        for (final entry in document.preferences.entries) {
          await _database
              .into(_database.appPreferences)
              .insert(
                AppPreferencesCompanion.insert(
                  key: entry.key,
                  value: entry.value,
                  updatedAt: DateTime.now(),
                ),
              );
        }

        for (final asset in assets) {
          await _receipts.delete(asset.relativePath);
        }
      });
    } on Object catch (error, stackTrace) {
      throw BackupException(
        '백업을 복원하지 못했습니다. 기존 데이터는 그대로입니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Built-in types survive the delete above, so restoring them by insert
  /// would collide on `code`. Upserting keeps the ids the records refer to.
  Future<void> _restoreTypes(List<Map<String, Object?>> rows) async {
    for (final row in rows) {
      await _database
          .into(_database.maintenanceTypes)
          .insertOnConflictUpdate(maintenanceTypeFromJson(row));
    }
  }
}

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(receiptStorageProvider),
  ),
);
