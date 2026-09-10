import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/features/settings/data/app_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late AppPreferencesRepository repository;

  setUp(() {
    database = openTestDatabase();
    repository = AppPreferencesRepository(database);
  });

  test('returns null for a key that was never written', () async {
    expect(await repository.read('home_layout'), isNull);
  });

  test('writes and reads a value back', () async {
    await repository.write('home_layout', 'status');

    expect(await repository.read('home_layout'), 'status');
  });

  test('overwrites an existing key instead of failing', () async {
    await repository.write('home_layout', 'status');
    await repository.write('home_layout', 'timeline');

    expect(await repository.read('home_layout'), 'timeline');
  });

  test('remove deletes the value', () async {
    await repository.write('home_layout', 'status');
    await repository.remove('home_layout');

    expect(await repository.read('home_layout'), isNull);
  });

  test('watch emits the current value and every later change', () async {
    final emitted = <String?>[];
    final subscription = repository.watch('home_layout').listen(emitted.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emitted, <String?>[null]);

    await repository.write('home_layout', 'status');
    await pumpEventQueue();
    expect(emitted.last, 'status');

    await repository.write('home_layout', 'timeline');
    await pumpEventQueue();
    expect(emitted.last, 'timeline');
  });
}
