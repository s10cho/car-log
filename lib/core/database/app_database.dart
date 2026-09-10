import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_preferences.dart';

part 'app_database.g.dart';

/// The single source of truth for all local data.
///
/// The UI renders from this database; remote integrations (Connected Car, AI)
/// write into it rather than being read directly by widgets.
@DriftDatabase(tables: [AppPreferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file for [name].
  AppDatabase.file(String name) : super(driftDatabase(name: name));

  @override
  int get schemaVersion => 1;
}
