import 'package:drift/drift.dart';

/// Key/value store for app-level user state that is not domain data, such as
/// the selected home layout or whether onboarding has been completed.
///
/// Domain entities (vehicles, maintenance records) get their own tables.
/// Credentials never go here — see `SecureStore`.
class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
