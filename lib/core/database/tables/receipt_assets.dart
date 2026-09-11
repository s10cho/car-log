import 'package:drift/drift.dart';

/// A receipt file the user attached to a maintenance record.
///
/// Only the file's **relative** path is stored. On iOS the app container is
/// re-created with a new UUID on reinstall and can move between OS updates, so
/// an absolute path saved today may point nowhere tomorrow. The path is
/// resolved against the documents directory at read time instead.
class ReceiptAssets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Path relative to the app documents directory, e.g. `receipts/<uuid>.jpg`.
  TextColumn get relativePath => text()();

  /// What the user called the file, shown when it cannot be previewed.
  TextColumn get fileName => text()();

  TextColumn get mimeType => text()();

  DateTimeColumn get createdAt => dateTime()();
}
