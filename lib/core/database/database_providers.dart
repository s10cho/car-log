import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import 'app_database.dart';

/// The app-wide database handle. Tests override this with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final config = ref.watch(appConfigProvider);
  final database = AppDatabase.file(config.databaseName);
  ref.onDispose(database.close);
  return database;
});
