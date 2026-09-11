import 'package:car_log/core/database/app_database.dart';
import 'package:car_log/core/database/built_in_maintenance_types.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  test('a fresh database has the whole built-in catalogue', () async {
    final database = openTestDatabase();

    final types = await database.select(database.maintenanceTypes).get();

    expect(
      types.map((t) => t.code),
      containsAll(builtInMaintenanceTypes.map((t) => t.code)),
    );
    expect(types.every((t) => t.isBuiltIn), isTrue);
  });

  test('every built-in type carries at least one interval dimension', () {
    for (final type in builtInMaintenanceTypes) {
      expect(
        type.distanceInterval != null || type.timeIntervalMonths != null,
        isTrue,
        reason: '${type.name} has nothing to calculate a due point from',
      );
    }
  });

  test('built-in codes are unique', () {
    final codes = builtInMaintenanceTypes.map((t) => t.code).toList();

    expect(codes.toSet(), hasLength(codes.length));
  });

  group('re-seeding', () {
    test('adds missing types without duplicating existing ones', () async {
      final database = openTestDatabase();
      final before = await database.select(database.maintenanceTypes).get();

      await database.seedBuiltInTypes();

      final after = await database.select(database.maintenanceTypes).get();
      expect(after, hasLength(before.length));
    });

    test('leaves an interval the user edited alone', () async {
      final database = openTestDatabase();
      await (database.update(
        database.maintenanceTypes,
      )..where((t) => t.code.equals(engineOilTypeCode))).write(
        const MaintenanceTypesCompanion(
          defaultDistanceInterval: Value(7000),
          name: Value('엔진오일(내 기준)'),
        ),
      );

      await database.seedBuiltInTypes();

      final engineOil = await (database.select(
        database.maintenanceTypes,
      )..where((t) => t.code.equals(engineOilTypeCode))).getSingle();
      expect(engineOil.defaultDistanceInterval, 7000);
      expect(engineOil.name, '엔진오일(내 기준)');
    });

    test('does not touch custom types', () async {
      final database = openTestDatabase();
      await database
          .into(database.maintenanceTypes)
          .insert(
            MaintenanceTypesCompanion.insert(
              name: '하부 코팅',
              defaultTimeIntervalMonths: const Value(24),
            ),
          );

      await database.seedBuiltInTypes();

      final custom = await (database.select(
        database.maintenanceTypes,
      )..where((t) => t.isBuiltIn.equals(false))).get();
      expect(custom, hasLength(1));
      expect(custom.single.name, '하부 코팅');
    });
  });

  test('upgrading a v2 database gains the rest of the catalogue', () async {
    // v2 는 엔진오일 하나만 심었다. 그 상태를 흉내 낸 뒤 마이그레이션을 태운다.
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await (database.delete(
      database.maintenanceTypes,
    )..where((t) => t.code.equals(engineOilTypeCode).not())).go();
    expect(
      await database.select(database.maintenanceTypes).get(),
      hasLength(1),
    );

    await database.seedBuiltInTypes();

    expect(
      await database.select(database.maintenanceTypes).get(),
      hasLength(builtInMaintenanceTypes.length),
    );
  });
}
