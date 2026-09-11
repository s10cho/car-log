import 'package:car_log/features/backup/domain/backup_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object?> valid({int? version}) => {
    'format_version': version ?? backupFormatVersion,
    'exported_at': '2026-03-01T12:00:00.000',
    'app_version': '1.0.0+1',
    'vehicles': <Object?>[],
    'maintenance_types': <Object?>[],
    'vehicle_maintenance_settings': <Object?>[],
    'maintenance_records': <Object?>[],
    'preferences': <String, Object?>{},
  };

  test('reads a well-formed document', () {
    final document = parseBackupDocument(valid());

    expect(document.formatVersion, backupFormatVersion);
    expect(document.exportedAt, DateTime(2026, 3, 1, 12));
    expect(document.appVersion, '1.0.0+1');
  });

  test('refuses something that is not a backup', () {
    expect(
      () => parseBackupDocument('그냥 텍스트'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => parseBackupDocument(const {'hello': 'world'}),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('refuses a backup from a newer app', () {
    expect(
      () => parseBackupDocument(valid(version: backupFormatVersion + 1)),
      throwsA(
        isA<BackupFormatException>().having(
          (e) => e.message,
          'message',
          contains('업데이트'),
        ),
      ),
    );
  });

  test('accepts a backup from an older format', () {
    // 과거 형식은 읽을 수 있어야 한다. 그게 버전을 두는 이유다.
    final document = parseBackupDocument(valid(version: 1));

    expect(document.formatVersion, 1);
  });

  test('a missing section is empty rather than an error', () {
    final json = valid()..remove('maintenance_records');

    expect(parseBackupDocument(json).records, isEmpty);
  });

  test('a corrupt section is refused, not partly read', () {
    final json = valid()..['vehicles'] = 'nonsense';

    expect(
      () => parseBackupDocument(json),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('a row that is not an object is refused', () {
    final json = valid()..['vehicles'] = <Object?>[1, 2, 3];

    expect(
      () => parseBackupDocument(json),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('an unreadable export date does not stop the import', () {
    final json = valid()..['exported_at'] = '언젠가';

    expect(parseBackupDocument(json).exportedAt.year, 1970);
  });

  test('non-string preferences are dropped', () {
    final json = valid()..['preferences'] = {'good': 'value', 'bad': 42};

    expect(parseBackupDocument(json).preferences, {'good': 'value'});
  });
}
