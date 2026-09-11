import 'package:meta/meta.dart';

/// Format version of an export file.
///
/// Bumped when the shape changes in a way an older app could misread. Import
/// refuses anything newer than it understands rather than guessing.
const int backupFormatVersion = 1;

/// What a backup file contains, in memory.
///
/// Deliberately a plain structure rather than database rows: an export has to
/// survive schema changes, so it carries its own shape and the importer maps it
/// onto whatever the tables look like today.
@immutable
class BackupDocument {
  const BackupDocument({
    required this.formatVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.vehicles,
    required this.maintenanceTypes,
    required this.settings,
    required this.records,
    required this.preferences,
  });

  final int formatVersion;
  final DateTime exportedAt;
  final String appVersion;

  final List<Map<String, Object?>> vehicles;
  final List<Map<String, Object?>> maintenanceTypes;
  final List<Map<String, Object?>> settings;
  final List<Map<String, Object?>> records;
  final Map<String, String> preferences;

  int get vehicleCount => vehicles.length;
  int get recordCount => records.length;

  Map<String, Object?> toJson() => {
    'format_version': formatVersion,
    'exported_at': exportedAt.toIso8601String(),
    'app_version': appVersion,
    'vehicles': vehicles,
    'maintenance_types': maintenanceTypes,
    'vehicle_maintenance_settings': settings,
    'maintenance_records': records,
    'preferences': preferences,
  };
}

/// A backup file could not be read.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Reads a backup file, refusing anything it cannot trust.
///
/// Import replaces everything the user has, so a half-understood file is worse
/// than no file at all: every check here fails loudly rather than importing
/// part of something.
BackupDocument parseBackupDocument(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const BackupFormatException('백업 파일 형식이 아닙니다.');
  }

  final version = json['format_version'];
  if (version is! int) {
    throw const BackupFormatException('백업 파일 형식이 아닙니다.');
  }
  if (version > backupFormatVersion) {
    throw BackupFormatException(
      '이 백업은 더 새로운 버전의 앱에서 만들어졌습니다 (형식 $version). 앱을 업데이트해 주세요.',
    );
  }

  return BackupDocument(
    formatVersion: version,
    exportedAt:
        DateTime.tryParse(json['exported_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    appVersion: json['app_version'] as String? ?? 'unknown',
    vehicles: _rows(json['vehicles'], 'vehicles'),
    maintenanceTypes: _rows(json['maintenance_types'], 'maintenance_types'),
    settings: _rows(
      json['vehicle_maintenance_settings'],
      'vehicle_maintenance_settings',
    ),
    records: _rows(json['maintenance_records'], 'maintenance_records'),
    preferences: _preferences(json['preferences']),
  );
}

List<Map<String, Object?>> _rows(Object? value, String name) {
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw BackupFormatException('백업 파일의 $name 항목이 손상되었습니다.');
  }
  return [
    for (final row in value)
      if (row is Map<String, Object?>)
        row
      else
        throw BackupFormatException('백업 파일의 $name 항목이 손상되었습니다.'),
  ];
}

Map<String, String> _preferences(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}
