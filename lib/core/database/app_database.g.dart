// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppPreference({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppPreference copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppPreference(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VehiclesTable extends Vehicles with TableInfo<$VehiclesTable, Vehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelYearMeta = const VerificationMeta(
    'modelYear',
  );
  @override
  late final GeneratedColumn<int> modelYear = GeneratedColumn<int>(
    'model_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vinMeta = const VerificationMeta('vin');
  @override
  late final GeneratedColumn<String> vin = GeneratedColumn<String>(
    'vin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _licensePlateMeta = const VerificationMeta(
    'licensePlate',
  );
  @override
  late final GeneratedColumn<String> licensePlate = GeneratedColumn<String>(
    'license_plate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentMileageMeta = const VerificationMeta(
    'currentMileage',
  );
  @override
  late final GeneratedColumn<int> currentMileage = GeneratedColumn<int>(
    'current_mileage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mileageUpdatedAtMeta = const VerificationMeta(
    'mileageUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> mileageUpdatedAt =
      GeneratedColumn<DateTime>(
        'mileage_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    manufacturer,
    model,
    modelYear,
    vin,
    licensePlate,
    currentMileage,
    mileageUpdatedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('model_year')) {
      context.handle(
        _modelYearMeta,
        modelYear.isAcceptableOrUnknown(data['model_year']!, _modelYearMeta),
      );
    }
    if (data.containsKey('vin')) {
      context.handle(
        _vinMeta,
        vin.isAcceptableOrUnknown(data['vin']!, _vinMeta),
      );
    }
    if (data.containsKey('license_plate')) {
      context.handle(
        _licensePlateMeta,
        licensePlate.isAcceptableOrUnknown(
          data['license_plate']!,
          _licensePlateMeta,
        ),
      );
    }
    if (data.containsKey('current_mileage')) {
      context.handle(
        _currentMileageMeta,
        currentMileage.isAcceptableOrUnknown(
          data['current_mileage']!,
          _currentMileageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentMileageMeta);
    }
    if (data.containsKey('mileage_updated_at')) {
      context.handle(
        _mileageUpdatedAtMeta,
        mileageUpdatedAt.isAcceptableOrUnknown(
          data['mileage_updated_at']!,
          _mileageUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mileageUpdatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      modelYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}model_year'],
      ),
      vin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vin'],
      ),
      licensePlate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_plate'],
      ),
      currentMileage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_mileage'],
      )!,
      mileageUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mileage_updated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class Vehicle extends DataClass implements Insertable<Vehicle> {
  final int id;

  /// What the user calls this car, e.g. "내 아반떼".
  final String displayName;
  final String? manufacturer;
  final String? model;
  final int? modelYear;

  /// Filled in manually for now. Lookup by plate or VIN needs an API whose
  /// commercial availability is still unverified (docs/decisions.md).
  final String? vin;
  final String? licensePlate;

  /// Odometer reading in kilometres, and when the user last confirmed it.
  final int currentMileage;
  final DateTime mileageUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Vehicle({
    required this.id,
    required this.displayName,
    this.manufacturer,
    this.model,
    this.modelYear,
    this.vin,
    this.licensePlate,
    required this.currentMileage,
    required this.mileageUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || manufacturer != null) {
      map['manufacturer'] = Variable<String>(manufacturer);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || modelYear != null) {
      map['model_year'] = Variable<int>(modelYear);
    }
    if (!nullToAbsent || vin != null) {
      map['vin'] = Variable<String>(vin);
    }
    if (!nullToAbsent || licensePlate != null) {
      map['license_plate'] = Variable<String>(licensePlate);
    }
    map['current_mileage'] = Variable<int>(currentMileage);
    map['mileage_updated_at'] = Variable<DateTime>(mileageUpdatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      manufacturer: manufacturer == null && nullToAbsent
          ? const Value.absent()
          : Value(manufacturer),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      modelYear: modelYear == null && nullToAbsent
          ? const Value.absent()
          : Value(modelYear),
      vin: vin == null && nullToAbsent ? const Value.absent() : Value(vin),
      licensePlate: licensePlate == null && nullToAbsent
          ? const Value.absent()
          : Value(licensePlate),
      currentMileage: Value(currentMileage),
      mileageUpdatedAt: Value(mileageUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Vehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vehicle(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      manufacturer: serializer.fromJson<String?>(json['manufacturer']),
      model: serializer.fromJson<String?>(json['model']),
      modelYear: serializer.fromJson<int?>(json['modelYear']),
      vin: serializer.fromJson<String?>(json['vin']),
      licensePlate: serializer.fromJson<String?>(json['licensePlate']),
      currentMileage: serializer.fromJson<int>(json['currentMileage']),
      mileageUpdatedAt: serializer.fromJson<DateTime>(json['mileageUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'manufacturer': serializer.toJson<String?>(manufacturer),
      'model': serializer.toJson<String?>(model),
      'modelYear': serializer.toJson<int?>(modelYear),
      'vin': serializer.toJson<String?>(vin),
      'licensePlate': serializer.toJson<String?>(licensePlate),
      'currentMileage': serializer.toJson<int>(currentMileage),
      'mileageUpdatedAt': serializer.toJson<DateTime>(mileageUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Vehicle copyWith({
    int? id,
    String? displayName,
    Value<String?> manufacturer = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<int?> modelYear = const Value.absent(),
    Value<String?> vin = const Value.absent(),
    Value<String?> licensePlate = const Value.absent(),
    int? currentMileage,
    DateTime? mileageUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Vehicle(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    manufacturer: manufacturer.present ? manufacturer.value : this.manufacturer,
    model: model.present ? model.value : this.model,
    modelYear: modelYear.present ? modelYear.value : this.modelYear,
    vin: vin.present ? vin.value : this.vin,
    licensePlate: licensePlate.present ? licensePlate.value : this.licensePlate,
    currentMileage: currentMileage ?? this.currentMileage,
    mileageUpdatedAt: mileageUpdatedAt ?? this.mileageUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Vehicle copyWithCompanion(VehiclesCompanion data) {
    return Vehicle(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      modelYear: data.modelYear.present ? data.modelYear.value : this.modelYear,
      vin: data.vin.present ? data.vin.value : this.vin,
      licensePlate: data.licensePlate.present
          ? data.licensePlate.value
          : this.licensePlate,
      currentMileage: data.currentMileage.present
          ? data.currentMileage.value
          : this.currentMileage,
      mileageUpdatedAt: data.mileageUpdatedAt.present
          ? data.mileageUpdatedAt.value
          : this.mileageUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vehicle(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('modelYear: $modelYear, ')
          ..write('vin: $vin, ')
          ..write('licensePlate: $licensePlate, ')
          ..write('currentMileage: $currentMileage, ')
          ..write('mileageUpdatedAt: $mileageUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    manufacturer,
    model,
    modelYear,
    vin,
    licensePlate,
    currentMileage,
    mileageUpdatedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vehicle &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.modelYear == this.modelYear &&
          other.vin == this.vin &&
          other.licensePlate == this.licensePlate &&
          other.currentMileage == this.currentMileage &&
          other.mileageUpdatedAt == this.mileageUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VehiclesCompanion extends UpdateCompanion<Vehicle> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String?> manufacturer;
  final Value<String?> model;
  final Value<int?> modelYear;
  final Value<String?> vin;
  final Value<String?> licensePlate;
  final Value<int> currentMileage;
  final Value<DateTime> mileageUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.modelYear = const Value.absent(),
    this.vin = const Value.absent(),
    this.licensePlate = const Value.absent(),
    this.currentMileage = const Value.absent(),
    this.mileageUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VehiclesCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.modelYear = const Value.absent(),
    this.vin = const Value.absent(),
    this.licensePlate = const Value.absent(),
    required int currentMileage,
    required DateTime mileageUpdatedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : displayName = Value(displayName),
       currentMileage = Value(currentMileage),
       mileageUpdatedAt = Value(mileageUpdatedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Vehicle> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<int>? modelYear,
    Expression<String>? vin,
    Expression<String>? licensePlate,
    Expression<int>? currentMileage,
    Expression<DateTime>? mileageUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (modelYear != null) 'model_year': modelYear,
      if (vin != null) 'vin': vin,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (currentMileage != null) 'current_mileage': currentMileage,
      if (mileageUpdatedAt != null) 'mileage_updated_at': mileageUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VehiclesCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String?>? manufacturer,
    Value<String?>? model,
    Value<int?>? modelYear,
    Value<String?>? vin,
    Value<String?>? licensePlate,
    Value<int>? currentMileage,
    Value<DateTime>? mileageUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      modelYear: modelYear ?? this.modelYear,
      vin: vin ?? this.vin,
      licensePlate: licensePlate ?? this.licensePlate,
      currentMileage: currentMileage ?? this.currentMileage,
      mileageUpdatedAt: mileageUpdatedAt ?? this.mileageUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (modelYear.present) {
      map['model_year'] = Variable<int>(modelYear.value);
    }
    if (vin.present) {
      map['vin'] = Variable<String>(vin.value);
    }
    if (licensePlate.present) {
      map['license_plate'] = Variable<String>(licensePlate.value);
    }
    if (currentMileage.present) {
      map['current_mileage'] = Variable<int>(currentMileage.value);
    }
    if (mileageUpdatedAt.present) {
      map['mileage_updated_at'] = Variable<DateTime>(mileageUpdatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('modelYear: $modelYear, ')
          ..write('vin: $vin, ')
          ..write('licensePlate: $licensePlate, ')
          ..write('currentMileage: $currentMileage, ')
          ..write('mileageUpdatedAt: $mileageUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceTypesTable extends MaintenanceTypes
    with TableInfo<$MaintenanceTypesTable, MaintenanceType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultDistanceIntervalMeta =
      const VerificationMeta('defaultDistanceInterval');
  @override
  late final GeneratedColumn<int> defaultDistanceInterval =
      GeneratedColumn<int>(
        'default_distance_interval',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _defaultTimeIntervalMonthsMeta =
      const VerificationMeta('defaultTimeIntervalMonths');
  @override
  late final GeneratedColumn<int> defaultTimeIntervalMonths =
      GeneratedColumn<int>(
        'default_time_interval_months',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    isBuiltIn,
    defaultDistanceInterval,
    defaultTimeIntervalMonths,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('default_distance_interval')) {
      context.handle(
        _defaultDistanceIntervalMeta,
        defaultDistanceInterval.isAcceptableOrUnknown(
          data['default_distance_interval']!,
          _defaultDistanceIntervalMeta,
        ),
      );
    }
    if (data.containsKey('default_time_interval_months')) {
      context.handle(
        _defaultTimeIntervalMonthsMeta,
        defaultTimeIntervalMonths.isAcceptableOrUnknown(
          data['default_time_interval_months']!,
          _defaultTimeIntervalMonthsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      defaultDistanceInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_distance_interval'],
      ),
      defaultTimeIntervalMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_time_interval_months'],
      ),
    );
  }

  @override
  $MaintenanceTypesTable createAlias(String alias) {
    return $MaintenanceTypesTable(attachedDatabase, alias);
  }
}

class MaintenanceType extends DataClass implements Insertable<MaintenanceType> {
  final int id;

  /// Stable identifier for built-in types, e.g. `engine_oil`. Null for types
  /// the user creates, which are identified by [name] alone.
  final String? code;
  final String name;
  final bool isBuiltIn;

  /// Recommended interval, used when a vehicle has no override of its own.
  /// Either may be null; a type with neither cannot produce a due date.
  final int? defaultDistanceInterval;
  final int? defaultTimeIntervalMonths;
  const MaintenanceType({
    required this.id,
    this.code,
    required this.name,
    required this.isBuiltIn,
    this.defaultDistanceInterval,
    this.defaultTimeIntervalMonths,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['name'] = Variable<String>(name);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    if (!nullToAbsent || defaultDistanceInterval != null) {
      map['default_distance_interval'] = Variable<int>(defaultDistanceInterval);
    }
    if (!nullToAbsent || defaultTimeIntervalMonths != null) {
      map['default_time_interval_months'] = Variable<int>(
        defaultTimeIntervalMonths,
      );
    }
    return map;
  }

  MaintenanceTypesCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceTypesCompanion(
      id: Value(id),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      name: Value(name),
      isBuiltIn: Value(isBuiltIn),
      defaultDistanceInterval: defaultDistanceInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDistanceInterval),
      defaultTimeIntervalMonths:
          defaultTimeIntervalMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultTimeIntervalMonths),
    );
  }

  factory MaintenanceType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceType(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String?>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      defaultDistanceInterval: serializer.fromJson<int?>(
        json['defaultDistanceInterval'],
      ),
      defaultTimeIntervalMonths: serializer.fromJson<int?>(
        json['defaultTimeIntervalMonths'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String?>(code),
      'name': serializer.toJson<String>(name),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'defaultDistanceInterval': serializer.toJson<int?>(
        defaultDistanceInterval,
      ),
      'defaultTimeIntervalMonths': serializer.toJson<int?>(
        defaultTimeIntervalMonths,
      ),
    };
  }

  MaintenanceType copyWith({
    int? id,
    Value<String?> code = const Value.absent(),
    String? name,
    bool? isBuiltIn,
    Value<int?> defaultDistanceInterval = const Value.absent(),
    Value<int?> defaultTimeIntervalMonths = const Value.absent(),
  }) => MaintenanceType(
    id: id ?? this.id,
    code: code.present ? code.value : this.code,
    name: name ?? this.name,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    defaultDistanceInterval: defaultDistanceInterval.present
        ? defaultDistanceInterval.value
        : this.defaultDistanceInterval,
    defaultTimeIntervalMonths: defaultTimeIntervalMonths.present
        ? defaultTimeIntervalMonths.value
        : this.defaultTimeIntervalMonths,
  );
  MaintenanceType copyWithCompanion(MaintenanceTypesCompanion data) {
    return MaintenanceType(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      defaultDistanceInterval: data.defaultDistanceInterval.present
          ? data.defaultDistanceInterval.value
          : this.defaultDistanceInterval,
      defaultTimeIntervalMonths: data.defaultTimeIntervalMonths.present
          ? data.defaultTimeIntervalMonths.value
          : this.defaultTimeIntervalMonths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceType(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('defaultDistanceInterval: $defaultDistanceInterval, ')
          ..write('defaultTimeIntervalMonths: $defaultTimeIntervalMonths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    isBuiltIn,
    defaultDistanceInterval,
    defaultTimeIntervalMonths,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceType &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.isBuiltIn == this.isBuiltIn &&
          other.defaultDistanceInterval == this.defaultDistanceInterval &&
          other.defaultTimeIntervalMonths == this.defaultTimeIntervalMonths);
}

class MaintenanceTypesCompanion extends UpdateCompanion<MaintenanceType> {
  final Value<int> id;
  final Value<String?> code;
  final Value<String> name;
  final Value<bool> isBuiltIn;
  final Value<int?> defaultDistanceInterval;
  final Value<int?> defaultTimeIntervalMonths;
  const MaintenanceTypesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.defaultDistanceInterval = const Value.absent(),
    this.defaultTimeIntervalMonths = const Value.absent(),
  });
  MaintenanceTypesCompanion.insert({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    required String name,
    this.isBuiltIn = const Value.absent(),
    this.defaultDistanceInterval = const Value.absent(),
    this.defaultTimeIntervalMonths = const Value.absent(),
  }) : name = Value(name);
  static Insertable<MaintenanceType> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? isBuiltIn,
    Expression<int>? defaultDistanceInterval,
    Expression<int>? defaultTimeIntervalMonths,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (defaultDistanceInterval != null)
        'default_distance_interval': defaultDistanceInterval,
      if (defaultTimeIntervalMonths != null)
        'default_time_interval_months': defaultTimeIntervalMonths,
    });
  }

  MaintenanceTypesCompanion copyWith({
    Value<int>? id,
    Value<String?>? code,
    Value<String>? name,
    Value<bool>? isBuiltIn,
    Value<int?>? defaultDistanceInterval,
    Value<int?>? defaultTimeIntervalMonths,
  }) {
    return MaintenanceTypesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      defaultDistanceInterval:
          defaultDistanceInterval ?? this.defaultDistanceInterval,
      defaultTimeIntervalMonths:
          defaultTimeIntervalMonths ?? this.defaultTimeIntervalMonths,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (defaultDistanceInterval.present) {
      map['default_distance_interval'] = Variable<int>(
        defaultDistanceInterval.value,
      );
    }
    if (defaultTimeIntervalMonths.present) {
      map['default_time_interval_months'] = Variable<int>(
        defaultTimeIntervalMonths.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceTypesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('defaultDistanceInterval: $defaultDistanceInterval, ')
          ..write('defaultTimeIntervalMonths: $defaultTimeIntervalMonths')
          ..write(')'))
        .toString();
  }
}

class $VehicleMaintenanceSettingsTable extends VehicleMaintenanceSettings
    with
        TableInfo<$VehicleMaintenanceSettingsTable, VehicleMaintenanceSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehicleMaintenanceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _maintenanceTypeIdMeta = const VerificationMeta(
    'maintenanceTypeId',
  );
  @override
  late final GeneratedColumn<int> maintenanceTypeId = GeneratedColumn<int>(
    'maintenance_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES maintenance_types (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _distanceIntervalMeta = const VerificationMeta(
    'distanceInterval',
  );
  @override
  late final GeneratedColumn<int> distanceInterval = GeneratedColumn<int>(
    'distance_interval',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeIntervalMonthsMeta =
      const VerificationMeta('timeIntervalMonths');
  @override
  late final GeneratedColumn<int> timeIntervalMonths = GeneratedColumn<int>(
    'time_interval_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationEnabledMeta =
      const VerificationMeta('notificationEnabled');
  @override
  late final GeneratedColumn<bool> notificationEnabled = GeneratedColumn<bool>(
    'notification_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notification_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    vehicleId,
    maintenanceTypeId,
    distanceInterval,
    timeIntervalMonths,
    notificationEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicle_maintenance_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<VehicleMaintenanceSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('maintenance_type_id')) {
      context.handle(
        _maintenanceTypeIdMeta,
        maintenanceTypeId.isAcceptableOrUnknown(
          data['maintenance_type_id']!,
          _maintenanceTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceTypeIdMeta);
    }
    if (data.containsKey('distance_interval')) {
      context.handle(
        _distanceIntervalMeta,
        distanceInterval.isAcceptableOrUnknown(
          data['distance_interval']!,
          _distanceIntervalMeta,
        ),
      );
    }
    if (data.containsKey('time_interval_months')) {
      context.handle(
        _timeIntervalMonthsMeta,
        timeIntervalMonths.isAcceptableOrUnknown(
          data['time_interval_months']!,
          _timeIntervalMonthsMeta,
        ),
      );
    }
    if (data.containsKey('notification_enabled')) {
      context.handle(
        _notificationEnabledMeta,
        notificationEnabled.isAcceptableOrUnknown(
          data['notification_enabled']!,
          _notificationEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vehicleId, maintenanceTypeId};
  @override
  VehicleMaintenanceSetting map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VehicleMaintenanceSetting(
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      maintenanceTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_type_id'],
      )!,
      distanceInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_interval'],
      ),
      timeIntervalMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_interval_months'],
      ),
      notificationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_enabled'],
      )!,
    );
  }

  @override
  $VehicleMaintenanceSettingsTable createAlias(String alias) {
    return $VehicleMaintenanceSettingsTable(attachedDatabase, alias);
  }
}

class VehicleMaintenanceSetting extends DataClass
    implements Insertable<VehicleMaintenanceSetting> {
  final int vehicleId;
  final int maintenanceTypeId;
  final int? distanceInterval;
  final int? timeIntervalMonths;

  /// Whether reminders are raised for this item on this vehicle.
  /// Absent row means enabled — the default is to remind.
  final bool notificationEnabled;
  const VehicleMaintenanceSetting({
    required this.vehicleId,
    required this.maintenanceTypeId,
    this.distanceInterval,
    this.timeIntervalMonths,
    required this.notificationEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['maintenance_type_id'] = Variable<int>(maintenanceTypeId);
    if (!nullToAbsent || distanceInterval != null) {
      map['distance_interval'] = Variable<int>(distanceInterval);
    }
    if (!nullToAbsent || timeIntervalMonths != null) {
      map['time_interval_months'] = Variable<int>(timeIntervalMonths);
    }
    map['notification_enabled'] = Variable<bool>(notificationEnabled);
    return map;
  }

  VehicleMaintenanceSettingsCompanion toCompanion(bool nullToAbsent) {
    return VehicleMaintenanceSettingsCompanion(
      vehicleId: Value(vehicleId),
      maintenanceTypeId: Value(maintenanceTypeId),
      distanceInterval: distanceInterval == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceInterval),
      timeIntervalMonths: timeIntervalMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(timeIntervalMonths),
      notificationEnabled: Value(notificationEnabled),
    );
  }

  factory VehicleMaintenanceSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VehicleMaintenanceSetting(
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      maintenanceTypeId: serializer.fromJson<int>(json['maintenanceTypeId']),
      distanceInterval: serializer.fromJson<int?>(json['distanceInterval']),
      timeIntervalMonths: serializer.fromJson<int?>(json['timeIntervalMonths']),
      notificationEnabled: serializer.fromJson<bool>(
        json['notificationEnabled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vehicleId': serializer.toJson<int>(vehicleId),
      'maintenanceTypeId': serializer.toJson<int>(maintenanceTypeId),
      'distanceInterval': serializer.toJson<int?>(distanceInterval),
      'timeIntervalMonths': serializer.toJson<int?>(timeIntervalMonths),
      'notificationEnabled': serializer.toJson<bool>(notificationEnabled),
    };
  }

  VehicleMaintenanceSetting copyWith({
    int? vehicleId,
    int? maintenanceTypeId,
    Value<int?> distanceInterval = const Value.absent(),
    Value<int?> timeIntervalMonths = const Value.absent(),
    bool? notificationEnabled,
  }) => VehicleMaintenanceSetting(
    vehicleId: vehicleId ?? this.vehicleId,
    maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
    distanceInterval: distanceInterval.present
        ? distanceInterval.value
        : this.distanceInterval,
    timeIntervalMonths: timeIntervalMonths.present
        ? timeIntervalMonths.value
        : this.timeIntervalMonths,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
  );
  VehicleMaintenanceSetting copyWithCompanion(
    VehicleMaintenanceSettingsCompanion data,
  ) {
    return VehicleMaintenanceSetting(
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      maintenanceTypeId: data.maintenanceTypeId.present
          ? data.maintenanceTypeId.value
          : this.maintenanceTypeId,
      distanceInterval: data.distanceInterval.present
          ? data.distanceInterval.value
          : this.distanceInterval,
      timeIntervalMonths: data.timeIntervalMonths.present
          ? data.timeIntervalMonths.value
          : this.timeIntervalMonths,
      notificationEnabled: data.notificationEnabled.present
          ? data.notificationEnabled.value
          : this.notificationEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VehicleMaintenanceSetting(')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceTypeId: $maintenanceTypeId, ')
          ..write('distanceInterval: $distanceInterval, ')
          ..write('timeIntervalMonths: $timeIntervalMonths, ')
          ..write('notificationEnabled: $notificationEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vehicleId,
    maintenanceTypeId,
    distanceInterval,
    timeIntervalMonths,
    notificationEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VehicleMaintenanceSetting &&
          other.vehicleId == this.vehicleId &&
          other.maintenanceTypeId == this.maintenanceTypeId &&
          other.distanceInterval == this.distanceInterval &&
          other.timeIntervalMonths == this.timeIntervalMonths &&
          other.notificationEnabled == this.notificationEnabled);
}

class VehicleMaintenanceSettingsCompanion
    extends UpdateCompanion<VehicleMaintenanceSetting> {
  final Value<int> vehicleId;
  final Value<int> maintenanceTypeId;
  final Value<int?> distanceInterval;
  final Value<int?> timeIntervalMonths;
  final Value<bool> notificationEnabled;
  final Value<int> rowid;
  const VehicleMaintenanceSettingsCompanion({
    this.vehicleId = const Value.absent(),
    this.maintenanceTypeId = const Value.absent(),
    this.distanceInterval = const Value.absent(),
    this.timeIntervalMonths = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehicleMaintenanceSettingsCompanion.insert({
    required int vehicleId,
    required int maintenanceTypeId,
    this.distanceInterval = const Value.absent(),
    this.timeIntervalMonths = const Value.absent(),
    this.notificationEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       maintenanceTypeId = Value(maintenanceTypeId);
  static Insertable<VehicleMaintenanceSetting> custom({
    Expression<int>? vehicleId,
    Expression<int>? maintenanceTypeId,
    Expression<int>? distanceInterval,
    Expression<int>? timeIntervalMonths,
    Expression<bool>? notificationEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (maintenanceTypeId != null) 'maintenance_type_id': maintenanceTypeId,
      if (distanceInterval != null) 'distance_interval': distanceInterval,
      if (timeIntervalMonths != null)
        'time_interval_months': timeIntervalMonths,
      if (notificationEnabled != null)
        'notification_enabled': notificationEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehicleMaintenanceSettingsCompanion copyWith({
    Value<int>? vehicleId,
    Value<int>? maintenanceTypeId,
    Value<int?>? distanceInterval,
    Value<int?>? timeIntervalMonths,
    Value<bool>? notificationEnabled,
    Value<int>? rowid,
  }) {
    return VehicleMaintenanceSettingsCompanion(
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
      distanceInterval: distanceInterval ?? this.distanceInterval,
      timeIntervalMonths: timeIntervalMonths ?? this.timeIntervalMonths,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (maintenanceTypeId.present) {
      map['maintenance_type_id'] = Variable<int>(maintenanceTypeId.value);
    }
    if (distanceInterval.present) {
      map['distance_interval'] = Variable<int>(distanceInterval.value);
    }
    if (timeIntervalMonths.present) {
      map['time_interval_months'] = Variable<int>(timeIntervalMonths.value);
    }
    if (notificationEnabled.present) {
      map['notification_enabled'] = Variable<bool>(notificationEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehicleMaintenanceSettingsCompanion(')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceTypeId: $maintenanceTypeId, ')
          ..write('distanceInterval: $distanceInterval, ')
          ..write('timeIntervalMonths: $timeIntervalMonths, ')
          ..write('notificationEnabled: $notificationEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceRecordsTable extends MaintenanceRecords
    with TableInfo<$MaintenanceRecordsTable, MaintenanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _maintenanceTypeIdMeta = const VerificationMeta(
    'maintenanceTypeId',
  );
  @override
  late final GeneratedColumn<int> maintenanceTypeId = GeneratedColumn<int>(
    'maintenance_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES maintenance_types (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _maintenanceDateMeta = const VerificationMeta(
    'maintenanceDate',
  );
  @override
  late final GeneratedColumn<DateTime> maintenanceDate =
      GeneratedColumn<DateTime>(
        'maintenance_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _mileageMeta = const VerificationMeta(
    'mileage',
  );
  @override
  late final GeneratedColumn<int> mileage = GeneratedColumn<int>(
    'mileage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<int> cost = GeneratedColumn<int>(
    'cost',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shopNameMeta = const VerificationMeta(
    'shopName',
  );
  @override
  late final GeneratedColumn<String> shopName = GeneratedColumn<String>(
    'shop_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    maintenanceTypeId,
    maintenanceDate,
    mileage,
    cost,
    shopName,
    memo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('maintenance_type_id')) {
      context.handle(
        _maintenanceTypeIdMeta,
        maintenanceTypeId.isAcceptableOrUnknown(
          data['maintenance_type_id']!,
          _maintenanceTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceTypeIdMeta);
    }
    if (data.containsKey('maintenance_date')) {
      context.handle(
        _maintenanceDateMeta,
        maintenanceDate.isAcceptableOrUnknown(
          data['maintenance_date']!,
          _maintenanceDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maintenanceDateMeta);
    }
    if (data.containsKey('mileage')) {
      context.handle(
        _mileageMeta,
        mileage.isAcceptableOrUnknown(data['mileage']!, _mileageMeta),
      );
    } else if (isInserting) {
      context.missing(_mileageMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('shop_name')) {
      context.handle(
        _shopNameMeta,
        shopName.isAcceptableOrUnknown(data['shop_name']!, _shopNameMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      maintenanceTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_type_id'],
      )!,
      maintenanceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}maintenance_date'],
      )!,
      mileage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mileage'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost'],
      ),
      shopName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shop_name'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MaintenanceRecordsTable createAlias(String alias) {
    return $MaintenanceRecordsTable(attachedDatabase, alias);
  }
}

class MaintenanceRecord extends DataClass
    implements Insertable<MaintenanceRecord> {
  final int id;
  final int vehicleId;
  final int maintenanceTypeId;
  final DateTime maintenanceDate;

  /// Odometer reading at the time of the work, in kilometres.
  final int mileage;

  /// Cost in KRW.
  final int? cost;
  final String? shopName;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.maintenanceTypeId,
    required this.maintenanceDate,
    required this.mileage,
    this.cost,
    this.shopName,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['maintenance_type_id'] = Variable<int>(maintenanceTypeId);
    map['maintenance_date'] = Variable<DateTime>(maintenanceDate);
    map['mileage'] = Variable<int>(mileage);
    if (!nullToAbsent || cost != null) {
      map['cost'] = Variable<int>(cost);
    }
    if (!nullToAbsent || shopName != null) {
      map['shop_name'] = Variable<String>(shopName);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MaintenanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceRecordsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      maintenanceTypeId: Value(maintenanceTypeId),
      maintenanceDate: Value(maintenanceDate),
      mileage: Value(mileage),
      cost: cost == null && nullToAbsent ? const Value.absent() : Value(cost),
      shopName: shopName == null && nullToAbsent
          ? const Value.absent()
          : Value(shopName),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MaintenanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceRecord(
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      maintenanceTypeId: serializer.fromJson<int>(json['maintenanceTypeId']),
      maintenanceDate: serializer.fromJson<DateTime>(json['maintenanceDate']),
      mileage: serializer.fromJson<int>(json['mileage']),
      cost: serializer.fromJson<int?>(json['cost']),
      shopName: serializer.fromJson<String?>(json['shopName']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'maintenanceTypeId': serializer.toJson<int>(maintenanceTypeId),
      'maintenanceDate': serializer.toJson<DateTime>(maintenanceDate),
      'mileage': serializer.toJson<int>(mileage),
      'cost': serializer.toJson<int?>(cost),
      'shopName': serializer.toJson<String?>(shopName),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MaintenanceRecord copyWith({
    int? id,
    int? vehicleId,
    int? maintenanceTypeId,
    DateTime? maintenanceDate,
    int? mileage,
    Value<int?> cost = const Value.absent(),
    Value<String?> shopName = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MaintenanceRecord(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
    maintenanceDate: maintenanceDate ?? this.maintenanceDate,
    mileage: mileage ?? this.mileage,
    cost: cost.present ? cost.value : this.cost,
    shopName: shopName.present ? shopName.value : this.shopName,
    memo: memo.present ? memo.value : this.memo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MaintenanceRecord copyWithCompanion(MaintenanceRecordsCompanion data) {
    return MaintenanceRecord(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      maintenanceTypeId: data.maintenanceTypeId.present
          ? data.maintenanceTypeId.value
          : this.maintenanceTypeId,
      maintenanceDate: data.maintenanceDate.present
          ? data.maintenanceDate.value
          : this.maintenanceDate,
      mileage: data.mileage.present ? data.mileage.value : this.mileage,
      cost: data.cost.present ? data.cost.value : this.cost,
      shopName: data.shopName.present ? data.shopName.value : this.shopName,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceRecord(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceTypeId: $maintenanceTypeId, ')
          ..write('maintenanceDate: $maintenanceDate, ')
          ..write('mileage: $mileage, ')
          ..write('cost: $cost, ')
          ..write('shopName: $shopName, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    maintenanceTypeId,
    maintenanceDate,
    mileage,
    cost,
    shopName,
    memo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceRecord &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.maintenanceTypeId == this.maintenanceTypeId &&
          other.maintenanceDate == this.maintenanceDate &&
          other.mileage == this.mileage &&
          other.cost == this.cost &&
          other.shopName == this.shopName &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MaintenanceRecordsCompanion extends UpdateCompanion<MaintenanceRecord> {
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<int> maintenanceTypeId;
  final Value<DateTime> maintenanceDate;
  final Value<int> mileage;
  final Value<int?> cost;
  final Value<String?> shopName;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MaintenanceRecordsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.maintenanceTypeId = const Value.absent(),
    this.maintenanceDate = const Value.absent(),
    this.mileage = const Value.absent(),
    this.cost = const Value.absent(),
    this.shopName = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MaintenanceRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int vehicleId,
    required int maintenanceTypeId,
    required DateTime maintenanceDate,
    required int mileage,
    this.cost = const Value.absent(),
    this.shopName = const Value.absent(),
    this.memo = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : vehicleId = Value(vehicleId),
       maintenanceTypeId = Value(maintenanceTypeId),
       maintenanceDate = Value(maintenanceDate),
       mileage = Value(mileage),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MaintenanceRecord> custom({
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<int>? maintenanceTypeId,
    Expression<DateTime>? maintenanceDate,
    Expression<int>? mileage,
    Expression<int>? cost,
    Expression<String>? shopName,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (maintenanceTypeId != null) 'maintenance_type_id': maintenanceTypeId,
      if (maintenanceDate != null) 'maintenance_date': maintenanceDate,
      if (mileage != null) 'mileage': mileage,
      if (cost != null) 'cost': cost,
      if (shopName != null) 'shop_name': shopName,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MaintenanceRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? vehicleId,
    Value<int>? maintenanceTypeId,
    Value<DateTime>? maintenanceDate,
    Value<int>? mileage,
    Value<int?>? cost,
    Value<String?>? shopName,
    Value<String?>? memo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MaintenanceRecordsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      mileage: mileage ?? this.mileage,
      cost: cost ?? this.cost,
      shopName: shopName ?? this.shopName,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (maintenanceTypeId.present) {
      map['maintenance_type_id'] = Variable<int>(maintenanceTypeId.value);
    }
    if (maintenanceDate.present) {
      map['maintenance_date'] = Variable<DateTime>(maintenanceDate.value);
    }
    if (mileage.present) {
      map['mileage'] = Variable<int>(mileage.value);
    }
    if (cost.present) {
      map['cost'] = Variable<int>(cost.value);
    }
    if (shopName.present) {
      map['shop_name'] = Variable<String>(shopName.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('maintenanceTypeId: $maintenanceTypeId, ')
          ..write('maintenanceDate: $maintenanceDate, ')
          ..write('mileage: $mileage, ')
          ..write('cost: $cost, ')
          ..write('shopName: $shopName, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $MaintenanceTypesTable maintenanceTypes = $MaintenanceTypesTable(
    this,
  );
  late final $VehicleMaintenanceSettingsTable vehicleMaintenanceSettings =
      $VehicleMaintenanceSettingsTable(this);
  late final $MaintenanceRecordsTable maintenanceRecords =
      $MaintenanceRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appPreferences,
    vehicles,
    maintenanceTypes,
    vehicleMaintenanceSettings,
    maintenanceRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vehicles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('vehicle_maintenance_settings', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'maintenance_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('vehicle_maintenance_settings', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vehicles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('maintenance_records', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPreferencesTable,
          AppPreference,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreference,
            BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>,
          ),
          AppPreference,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$AppDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppPreferencesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppPreferencesTable, AppPreference>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppPreferencesTable,
                    AppPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPreferencesTable,
      AppPreference,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreference,
        BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>,
      ),
      AppPreference,
      PrefetchHooks Function()
    >;
typedef $$VehiclesTableCreateCompanionBuilder = VehiclesCompanion Function({
  Value<int> id,
  required String displayName,
  Value<String?> manufacturer,
  Value<String?> model,
  Value<int?> modelYear,
  Value<String?> vin,
  Value<String?> licensePlate,
  required int currentMileage,
  required DateTime mileageUpdatedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$VehiclesTableUpdateCompanionBuilder = VehiclesCompanion Function({
  Value<int> id,
  Value<String> displayName,
  Value<String?> manufacturer,
  Value<String?> model,
  Value<int?> modelYear,
  Value<String?> vin,
  Value<String?> licensePlate,
  Value<int> currentMileage,
  Value<DateTime> mileageUpdatedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$VehiclesTableReferences
    extends BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle> {
  $$VehiclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $VehicleMaintenanceSettingsTable,
    List<VehicleMaintenanceSetting>
  >
  _vehicleMaintenanceSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vehicleMaintenanceSettings,
        aliasName: 'vehicles__id__vehicle_maintenance_settings__vehicle_id',
      );

  $$VehicleMaintenanceSettingsTableProcessedTableManager
  get vehicleMaintenanceSettingsRefs {
    final manager = $$VehicleMaintenanceSettingsTableTableManager(
      $_db,
      $_db.vehicleMaintenanceSettings,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _vehicleMaintenanceSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MaintenanceRecordsTable, List<MaintenanceRecord>>
  _maintenanceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.maintenanceRecords,
        aliasName: 'vehicles__id__maintenance_records__vehicle_id',
      );

  $$MaintenanceRecordsTableProcessedTableManager get maintenanceRecordsRefs {
    final manager = $$MaintenanceRecordsTableTableManager(
      $_db,
      $_db.maintenanceRecords,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _maintenanceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modelYear => $composableBuilder(
    column: $table.modelYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vin => $composableBuilder(
    column: $table.vin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licensePlate => $composableBuilder(
    column: $table.licensePlate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentMileage => $composableBuilder(
    column: $table.currentMileage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mileageUpdatedAt => $composableBuilder(
    column: $table.mileageUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> vehicleMaintenanceSettingsRefs(
    Expression<bool> Function($$VehicleMaintenanceSettingsTableFilterComposer f)
    f,
  ) {
    final $$VehicleMaintenanceSettingsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vehicleMaintenanceSettings,
          getReferencedColumn: (t) => t.vehicleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VehicleMaintenanceSettingsTableFilterComposer(
                $db: $db,
                $table: $db.vehicleMaintenanceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> maintenanceRecordsRefs(
    Expression<bool> Function($$MaintenanceRecordsTableFilterComposer f) f,
  ) {
    final $$MaintenanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceRecords,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modelYear => $composableBuilder(
    column: $table.modelYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vin => $composableBuilder(
    column: $table.vin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licensePlate => $composableBuilder(
    column: $table.licensePlate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentMileage => $composableBuilder(
    column: $table.currentMileage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mileageUpdatedAt => $composableBuilder(
    column: $table.mileageUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get modelYear =>
      $composableBuilder(column: $table.modelYear, builder: (column) => column);

  GeneratedColumn<String> get vin =>
      $composableBuilder(column: $table.vin, builder: (column) => column);

  GeneratedColumn<String> get licensePlate => $composableBuilder(
    column: $table.licensePlate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentMileage => $composableBuilder(
    column: $table.currentMileage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get mileageUpdatedAt => $composableBuilder(
    column: $table.mileageUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> vehicleMaintenanceSettingsRefs<T extends Object>(
    Expression<T> Function(
      $$VehicleMaintenanceSettingsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$VehicleMaintenanceSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vehicleMaintenanceSettings,
          getReferencedColumn: (t) => t.vehicleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VehicleMaintenanceSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.vehicleMaintenanceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> maintenanceRecordsRefs<T extends Object>(
    Expression<T> Function($$MaintenanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$MaintenanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.maintenanceRecords,
          getReferencedColumn: (t) => t.vehicleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MaintenanceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.maintenanceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          Vehicle,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (Vehicle, $$VehiclesTableReferences),
          Vehicle,
          PrefetchHooks Function({
            bool vehicleMaintenanceSettingsRefs,
            bool maintenanceRecordsRefs,
          })
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> modelYear = const Value.absent(),
                Value<String?> vin = const Value.absent(),
                Value<String?> licensePlate = const Value.absent(),
                Value<int> currentMileage = const Value.absent(),
                Value<DateTime> mileageUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                displayName: displayName,
                manufacturer: manufacturer,
                model: model,
                modelYear: modelYear,
                vin: vin,
                licensePlate: licensePlate,
                currentMileage: currentMileage,
                mileageUpdatedAt: mileageUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                Value<String?> manufacturer = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> modelYear = const Value.absent(),
                Value<String?> vin = const Value.absent(),
                Value<String?> licensePlate = const Value.absent(),
                required int currentMileage,
                required DateTime mileageUpdatedAt,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => VehiclesCompanion.insert(
                id: id,
                displayName: displayName,
                manufacturer: manufacturer,
                model: model,
                modelYear: modelYear,
                vin: vin,
                licensePlate: licensePlate,
                currentMileage: currentMileage,
                mileageUpdatedAt: mileageUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VehiclesTable, Vehicle>(table),
                  $$VehiclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                vehicleMaintenanceSettingsRefs = false,
                maintenanceRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (vehicleMaintenanceSettingsRefs)
                      db.vehicleMaintenanceSettings,
                    if (maintenanceRecordsRefs) db.maintenanceRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (vehicleMaintenanceSettingsRefs)
                        await $_getPrefetchedData<
                          Vehicle,
                          $VehiclesTable,
                          VehicleMaintenanceSetting
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._vehicleMaintenanceSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).vehicleMaintenanceSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vehicleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (maintenanceRecordsRefs)
                        await $_getPrefetchedData<
                          Vehicle,
                          $VehiclesTable,
                          MaintenanceRecord
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._maintenanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).maintenanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vehicleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      Vehicle,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (Vehicle, $$VehiclesTableReferences),
      Vehicle,
      PrefetchHooks Function({
        bool vehicleMaintenanceSettingsRefs,
        bool maintenanceRecordsRefs,
      })
    >;
typedef $$MaintenanceTypesTableCreateCompanionBuilder =
    MaintenanceTypesCompanion Function({
      Value<int> id,
      Value<String?> code,
      required String name,
      Value<bool> isBuiltIn,
      Value<int?> defaultDistanceInterval,
      Value<int?> defaultTimeIntervalMonths,
    });
typedef $$MaintenanceTypesTableUpdateCompanionBuilder =
    MaintenanceTypesCompanion Function({
      Value<int> id,
      Value<String?> code,
      Value<String> name,
      Value<bool> isBuiltIn,
      Value<int?> defaultDistanceInterval,
      Value<int?> defaultTimeIntervalMonths,
    });

final class $$MaintenanceTypesTableReferences
    extends
        BaseReferences<_$AppDatabase, $MaintenanceTypesTable, MaintenanceType> {
  $$MaintenanceTypesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $VehicleMaintenanceSettingsTable,
    List<VehicleMaintenanceSetting>
  >
  _vehicleMaintenanceSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vehicleMaintenanceSettings,
        aliasName: 'maintenance_types__id__vehicle_maintenance_settings__maintenance_type_id',
      );

  $$VehicleMaintenanceSettingsTableProcessedTableManager
  get vehicleMaintenanceSettingsRefs {
    final manager = $$VehicleMaintenanceSettingsTableTableManager(
      $_db,
      $_db.vehicleMaintenanceSettings,
    ).filter((f) => f.maintenanceTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _vehicleMaintenanceSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MaintenanceRecordsTable, List<MaintenanceRecord>>
  _maintenanceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.maintenanceRecords,
        aliasName:
            'maintenance_types__id__maintenance_records__maintenance_type_id',
      );

  $$MaintenanceRecordsTableProcessedTableManager get maintenanceRecordsRefs {
    final manager = $$MaintenanceRecordsTableTableManager(
      $_db,
      $_db.maintenanceRecords,
    ).filter((f) => f.maintenanceTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _maintenanceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MaintenanceTypesTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenanceTypesTable> {
  $$MaintenanceTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultDistanceInterval => $composableBuilder(
    column: $table.defaultDistanceInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultTimeIntervalMonths => $composableBuilder(
    column: $table.defaultTimeIntervalMonths,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> vehicleMaintenanceSettingsRefs(
    Expression<bool> Function($$VehicleMaintenanceSettingsTableFilterComposer f)
    f,
  ) {
    final $$VehicleMaintenanceSettingsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vehicleMaintenanceSettings,
          getReferencedColumn: (t) => t.maintenanceTypeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VehicleMaintenanceSettingsTableFilterComposer(
                $db: $db,
                $table: $db.vehicleMaintenanceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> maintenanceRecordsRefs(
    Expression<bool> Function($$MaintenanceRecordsTableFilterComposer f) f,
  ) {
    final $$MaintenanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceRecords,
      getReferencedColumn: (t) => t.maintenanceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MaintenanceTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenanceTypesTable> {
  $$MaintenanceTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultDistanceInterval => $composableBuilder(
    column: $table.defaultDistanceInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultTimeIntervalMonths => $composableBuilder(
    column: $table.defaultTimeIntervalMonths,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaintenanceTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenanceTypesTable> {
  $$MaintenanceTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<int> get defaultDistanceInterval => $composableBuilder(
    column: $table.defaultDistanceInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultTimeIntervalMonths => $composableBuilder(
    column: $table.defaultTimeIntervalMonths,
    builder: (column) => column,
  );

  Expression<T> vehicleMaintenanceSettingsRefs<T extends Object>(
    Expression<T> Function(
      $$VehicleMaintenanceSettingsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$VehicleMaintenanceSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vehicleMaintenanceSettings,
          getReferencedColumn: (t) => t.maintenanceTypeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VehicleMaintenanceSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.vehicleMaintenanceSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> maintenanceRecordsRefs<T extends Object>(
    Expression<T> Function($$MaintenanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$MaintenanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.maintenanceRecords,
          getReferencedColumn: (t) => t.maintenanceTypeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MaintenanceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.maintenanceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MaintenanceTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenanceTypesTable,
          MaintenanceType,
          $$MaintenanceTypesTableFilterComposer,
          $$MaintenanceTypesTableOrderingComposer,
          $$MaintenanceTypesTableAnnotationComposer,
          $$MaintenanceTypesTableCreateCompanionBuilder,
          $$MaintenanceTypesTableUpdateCompanionBuilder,
          (MaintenanceType, $$MaintenanceTypesTableReferences),
          MaintenanceType,
          PrefetchHooks Function({
            bool vehicleMaintenanceSettingsRefs,
            bool maintenanceRecordsRefs,
          })
        > {
  $$MaintenanceTypesTableTableManager(
    _$AppDatabase db,
    $MaintenanceTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int?> defaultDistanceInterval = const Value.absent(),
                Value<int?> defaultTimeIntervalMonths = const Value.absent(),
              }) => MaintenanceTypesCompanion(
                id: id,
                code: code,
                name: name,
                isBuiltIn: isBuiltIn,
                defaultDistanceInterval: defaultDistanceInterval,
                defaultTimeIntervalMonths: defaultTimeIntervalMonths,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> code = const Value.absent(),
                required String name,
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int?> defaultDistanceInterval = const Value.absent(),
                Value<int?> defaultTimeIntervalMonths = const Value.absent(),
              }) => MaintenanceTypesCompanion.insert(
                id: id,
                code: code,
                name: name,
                isBuiltIn: isBuiltIn,
                defaultDistanceInterval: defaultDistanceInterval,
                defaultTimeIntervalMonths: defaultTimeIntervalMonths,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MaintenanceTypesTable, MaintenanceType>(table),
                  $$MaintenanceTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                vehicleMaintenanceSettingsRefs = false,
                maintenanceRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (vehicleMaintenanceSettingsRefs)
                      db.vehicleMaintenanceSettings,
                    if (maintenanceRecordsRefs) db.maintenanceRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (vehicleMaintenanceSettingsRefs)
                        await $_getPrefetchedData<
                          MaintenanceType,
                          $MaintenanceTypesTable,
                          VehicleMaintenanceSetting
                        >(
                          currentTable: table,
                          referencedTable: $$MaintenanceTypesTableReferences
                              ._vehicleMaintenanceSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MaintenanceTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).vehicleMaintenanceSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.maintenanceTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (maintenanceRecordsRefs)
                        await $_getPrefetchedData<
                          MaintenanceType,
                          $MaintenanceTypesTable,
                          MaintenanceRecord
                        >(
                          currentTable: table,
                          referencedTable: $$MaintenanceTypesTableReferences
                              ._maintenanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MaintenanceTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).maintenanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.maintenanceTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MaintenanceTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenanceTypesTable,
      MaintenanceType,
      $$MaintenanceTypesTableFilterComposer,
      $$MaintenanceTypesTableOrderingComposer,
      $$MaintenanceTypesTableAnnotationComposer,
      $$MaintenanceTypesTableCreateCompanionBuilder,
      $$MaintenanceTypesTableUpdateCompanionBuilder,
      (MaintenanceType, $$MaintenanceTypesTableReferences),
      MaintenanceType,
      PrefetchHooks Function({
        bool vehicleMaintenanceSettingsRefs,
        bool maintenanceRecordsRefs,
      })
    >;
typedef $$VehicleMaintenanceSettingsTableCreateCompanionBuilder =
    VehicleMaintenanceSettingsCompanion Function({
      required int vehicleId,
      required int maintenanceTypeId,
      Value<int?> distanceInterval,
      Value<int?> timeIntervalMonths,
      Value<bool> notificationEnabled,
      Value<int> rowid,
    });
typedef $$VehicleMaintenanceSettingsTableUpdateCompanionBuilder =
    VehicleMaintenanceSettingsCompanion Function({
      Value<int> vehicleId,
      Value<int> maintenanceTypeId,
      Value<int?> distanceInterval,
      Value<int?> timeIntervalMonths,
      Value<bool> notificationEnabled,
      Value<int> rowid,
    });

final class $$VehicleMaintenanceSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VehicleMaintenanceSettingsTable,
          VehicleMaintenanceSetting
        > {
  $$VehicleMaintenanceSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) => db.vehicles
      .createAlias('vehicle_maintenance_settings__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MaintenanceTypesTable _maintenanceTypeIdTable(
    _$AppDatabase db,
  ) => db.maintenanceTypes.createAlias(
    'vehicle_maintenance_settings__maintenance_type_id__maintenance_types__id',
  );

  $$MaintenanceTypesTableProcessedTableManager get maintenanceTypeId {
    final $_column = $_itemColumn<int>('maintenance_type_id')!;

    final manager = $$MaintenanceTypesTableTableManager(
      $_db,
      $_db.maintenanceTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_maintenanceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VehicleMaintenanceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $VehicleMaintenanceSettingsTable> {
  $$VehicleMaintenanceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get distanceInterval => $composableBuilder(
    column: $table.distanceInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeIntervalMonths => $composableBuilder(
    column: $table.timeIntervalMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationEnabled => $composableBuilder(
    column: $table.notificationEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MaintenanceTypesTableFilterComposer get maintenanceTypeId {
    final $$MaintenanceTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.maintenanceTypeId,
      referencedTable: $db.maintenanceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTypesTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VehicleMaintenanceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $VehicleMaintenanceSettingsTable> {
  $$VehicleMaintenanceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get distanceInterval => $composableBuilder(
    column: $table.distanceInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeIntervalMonths => $composableBuilder(
    column: $table.timeIntervalMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationEnabled => $composableBuilder(
    column: $table.notificationEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MaintenanceTypesTableOrderingComposer get maintenanceTypeId {
    final $$MaintenanceTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.maintenanceTypeId,
      referencedTable: $db.maintenanceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTypesTableOrderingComposer(
            $db: $db,
            $table: $db.maintenanceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VehicleMaintenanceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehicleMaintenanceSettingsTable> {
  $$VehicleMaintenanceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get distanceInterval => $composableBuilder(
    column: $table.distanceInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeIntervalMonths => $composableBuilder(
    column: $table.timeIntervalMonths,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationEnabled => $composableBuilder(
    column: $table.notificationEnabled,
    builder: (column) => column,
  );

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MaintenanceTypesTableAnnotationComposer get maintenanceTypeId {
    final $$MaintenanceTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.maintenanceTypeId,
      referencedTable: $db.maintenanceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.maintenanceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VehicleMaintenanceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehicleMaintenanceSettingsTable,
          VehicleMaintenanceSetting,
          $$VehicleMaintenanceSettingsTableFilterComposer,
          $$VehicleMaintenanceSettingsTableOrderingComposer,
          $$VehicleMaintenanceSettingsTableAnnotationComposer,
          $$VehicleMaintenanceSettingsTableCreateCompanionBuilder,
          $$VehicleMaintenanceSettingsTableUpdateCompanionBuilder,
          (
            VehicleMaintenanceSetting,
            $$VehicleMaintenanceSettingsTableReferences,
          ),
          VehicleMaintenanceSetting,
          PrefetchHooks Function({bool vehicleId, bool maintenanceTypeId})
        > {
  $$VehicleMaintenanceSettingsTableTableManager(
    _$AppDatabase db,
    $VehicleMaintenanceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehicleMaintenanceSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$VehicleMaintenanceSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VehicleMaintenanceSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> vehicleId = const Value.absent(),
                Value<int> maintenanceTypeId = const Value.absent(),
                Value<int?> distanceInterval = const Value.absent(),
                Value<int?> timeIntervalMonths = const Value.absent(),
                Value<bool> notificationEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehicleMaintenanceSettingsCompanion(
                vehicleId: vehicleId,
                maintenanceTypeId: maintenanceTypeId,
                distanceInterval: distanceInterval,
                timeIntervalMonths: timeIntervalMonths,
                notificationEnabled: notificationEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int vehicleId,
                required int maintenanceTypeId,
                Value<int?> distanceInterval = const Value.absent(),
                Value<int?> timeIntervalMonths = const Value.absent(),
                Value<bool> notificationEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehicleMaintenanceSettingsCompanion.insert(
                vehicleId: vehicleId,
                maintenanceTypeId: maintenanceTypeId,
                distanceInterval: distanceInterval,
                timeIntervalMonths: timeIntervalMonths,
                notificationEnabled: notificationEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $VehicleMaintenanceSettingsTable,
                    VehicleMaintenanceSetting
                  >(table),
                  $$VehicleMaintenanceSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({vehicleId = false, maintenanceTypeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (vehicleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.vehicleId,
                            referencedTable:
                                $$VehicleMaintenanceSettingsTableReferences
                                    ._vehicleIdTable(db),
                            referencedColumn:
                                $$VehicleMaintenanceSettingsTableReferences
                                    ._vehicleIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (maintenanceTypeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.maintenanceTypeId,
                            referencedTable:
                                $$VehicleMaintenanceSettingsTableReferences
                                    ._maintenanceTypeIdTable(db),
                            referencedColumn:
                                $$VehicleMaintenanceSettingsTableReferences
                                    ._maintenanceTypeIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$VehicleMaintenanceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehicleMaintenanceSettingsTable,
      VehicleMaintenanceSetting,
      $$VehicleMaintenanceSettingsTableFilterComposer,
      $$VehicleMaintenanceSettingsTableOrderingComposer,
      $$VehicleMaintenanceSettingsTableAnnotationComposer,
      $$VehicleMaintenanceSettingsTableCreateCompanionBuilder,
      $$VehicleMaintenanceSettingsTableUpdateCompanionBuilder,
      (VehicleMaintenanceSetting, $$VehicleMaintenanceSettingsTableReferences),
      VehicleMaintenanceSetting,
      PrefetchHooks Function({bool vehicleId, bool maintenanceTypeId})
    >;
typedef $$MaintenanceRecordsTableCreateCompanionBuilder =
    MaintenanceRecordsCompanion Function({
      Value<int> id,
      required int vehicleId,
      required int maintenanceTypeId,
      required DateTime maintenanceDate,
      required int mileage,
      Value<int?> cost,
      Value<String?> shopName,
      Value<String?> memo,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$MaintenanceRecordsTableUpdateCompanionBuilder =
    MaintenanceRecordsCompanion Function({
      Value<int> id,
      Value<int> vehicleId,
      Value<int> maintenanceTypeId,
      Value<DateTime> maintenanceDate,
      Value<int> mileage,
      Value<int?> cost,
      Value<String?> shopName,
      Value<String?> memo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$MaintenanceRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MaintenanceRecordsTable,
          MaintenanceRecord
        > {
  $$MaintenanceRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('maintenance_records__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MaintenanceTypesTable _maintenanceTypeIdTable(_$AppDatabase db) =>
      db.maintenanceTypes.createAlias(
        'maintenance_records__maintenance_type_id__maintenance_types__id',
      );

  $$MaintenanceTypesTableProcessedTableManager get maintenanceTypeId {
    final $_column = $_itemColumn<int>('maintenance_type_id')!;

    final manager = $$MaintenanceTypesTableTableManager(
      $_db,
      $_db.maintenanceTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_maintenanceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MaintenanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenanceRecordsTable> {
  $$MaintenanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get maintenanceDate => $composableBuilder(
    column: $table.maintenanceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mileage => $composableBuilder(
    column: $table.mileage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MaintenanceTypesTableFilterComposer get maintenanceTypeId {
    final $$MaintenanceTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.maintenanceTypeId,
      referencedTable: $db.maintenanceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTypesTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenanceRecordsTable> {
  $$MaintenanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get maintenanceDate => $composableBuilder(
    column: $table.maintenanceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mileage => $composableBuilder(
    column: $table.mileage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shopName => $composableBuilder(
    column: $table.shopName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MaintenanceTypesTableOrderingComposer get maintenanceTypeId {
    final $$MaintenanceTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.maintenanceTypeId,
      referencedTable: $db.maintenanceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTypesTableOrderingComposer(
            $db: $db,
            $table: $db.maintenanceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenanceRecordsTable> {
  $$MaintenanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get maintenanceDate => $composableBuilder(
    column: $table.maintenanceDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mileage =>
      $composableBuilder(column: $table.mileage, builder: (column) => column);

  GeneratedColumn<int> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<String> get shopName =>
      $composableBuilder(column: $table.shopName, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MaintenanceTypesTableAnnotationComposer get maintenanceTypeId {
    final $$MaintenanceTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.maintenanceTypeId,
      referencedTable: $db.maintenanceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.maintenanceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenanceRecordsTable,
          MaintenanceRecord,
          $$MaintenanceRecordsTableFilterComposer,
          $$MaintenanceRecordsTableOrderingComposer,
          $$MaintenanceRecordsTableAnnotationComposer,
          $$MaintenanceRecordsTableCreateCompanionBuilder,
          $$MaintenanceRecordsTableUpdateCompanionBuilder,
          (MaintenanceRecord, $$MaintenanceRecordsTableReferences),
          MaintenanceRecord,
          PrefetchHooks Function({bool vehicleId, bool maintenanceTypeId})
        > {
  $$MaintenanceRecordsTableTableManager(
    _$AppDatabase db,
    $MaintenanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> vehicleId = const Value.absent(),
                Value<int> maintenanceTypeId = const Value.absent(),
                Value<DateTime> maintenanceDate = const Value.absent(),
                Value<int> mileage = const Value.absent(),
                Value<int?> cost = const Value.absent(),
                Value<String?> shopName = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MaintenanceRecordsCompanion(
                id: id,
                vehicleId: vehicleId,
                maintenanceTypeId: maintenanceTypeId,
                maintenanceDate: maintenanceDate,
                mileage: mileage,
                cost: cost,
                shopName: shopName,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int vehicleId,
                required int maintenanceTypeId,
                required DateTime maintenanceDate,
                required int mileage,
                Value<int?> cost = const Value.absent(),
                Value<String?> shopName = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => MaintenanceRecordsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                maintenanceTypeId: maintenanceTypeId,
                maintenanceDate: maintenanceDate,
                mileage: mileage,
                cost: cost,
                shopName: shopName,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MaintenanceRecordsTable, MaintenanceRecord>(
                    table,
                  ),
                  $$MaintenanceRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({vehicleId = false, maintenanceTypeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (vehicleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.vehicleId,
                            referencedTable: $$MaintenanceRecordsTableReferences
                                ._vehicleIdTable(db),
                            referencedColumn:
                                $$MaintenanceRecordsTableReferences
                                    ._vehicleIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (maintenanceTypeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.maintenanceTypeId,
                            referencedTable: $$MaintenanceRecordsTableReferences
                                ._maintenanceTypeIdTable(db),
                            referencedColumn:
                                $$MaintenanceRecordsTableReferences
                                    ._maintenanceTypeIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$MaintenanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenanceRecordsTable,
      MaintenanceRecord,
      $$MaintenanceRecordsTableFilterComposer,
      $$MaintenanceRecordsTableOrderingComposer,
      $$MaintenanceRecordsTableAnnotationComposer,
      $$MaintenanceRecordsTableCreateCompanionBuilder,
      $$MaintenanceRecordsTableUpdateCompanionBuilder,
      (MaintenanceRecord, $$MaintenanceRecordsTableReferences),
      MaintenanceRecord,
      PrefetchHooks Function({bool vehicleId, bool maintenanceTypeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$MaintenanceTypesTableTableManager get maintenanceTypes =>
      $$MaintenanceTypesTableTableManager(_db, _db.maintenanceTypes);
  $$VehicleMaintenanceSettingsTableTableManager
  get vehicleMaintenanceSettings =>
      $$VehicleMaintenanceSettingsTableTableManager(
        _db,
        _db.vehicleMaintenanceSettings,
      );
  $$MaintenanceRecordsTableTableManager get maintenanceRecords =>
      $$MaintenanceRecordsTableTableManager(_db, _db.maintenanceRecords);
}
