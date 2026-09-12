import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Explicit mapping between database rows and the backup format.
///
/// The format is written out by hand rather than reusing Drift's row JSON: a
/// backup has to be readable by a future version of the app whose tables have
/// moved on, and generated names would drift with the schema. Everything here
/// is a deliberate, stable field name.

Map<String, Object?> vehicleToJson(Vehicle row) => {
  'id': row.id,
  'display_name': row.displayName,
  'body_style': row.bodyStyle,
  'manufacturer': row.manufacturer,
  'model': row.model,
  'model_year': row.modelYear,
  'vin': row.vin,
  'license_plate': row.licensePlate,
  'current_mileage': row.currentMileage,
  'mileage_updated_at': row.mileageUpdatedAt.toIso8601String(),
  'created_at': row.createdAt.toIso8601String(),
  'updated_at': row.updatedAt.toIso8601String(),
};

VehiclesCompanion vehicleFromJson(Map<String, Object?> json) =>
    VehiclesCompanion.insert(
      id: Value(_int(json['id'])!),
      displayName: _string(json['display_name']) ?? '이름 없는 차량',
      bodyStyle: Value(_string(json['body_style'])),
      manufacturer: Value(_string(json['manufacturer'])),
      model: Value(_string(json['model'])),
      modelYear: Value(_int(json['model_year'])),
      vin: Value(_string(json['vin'])),
      licensePlate: Value(_string(json['license_plate'])),
      currentMileage: _int(json['current_mileage']) ?? 0,
      mileageUpdatedAt: _date(json['mileage_updated_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );

Map<String, Object?> maintenanceTypeToJson(MaintenanceType row) => {
  'id': row.id,
  'code': row.code,
  'name': row.name,
  'is_built_in': row.isBuiltIn,
  'default_distance_interval': row.defaultDistanceInterval,
  'default_time_interval_months': row.defaultTimeIntervalMonths,
};

MaintenanceTypesCompanion maintenanceTypeFromJson(Map<String, Object?> json) =>
    MaintenanceTypesCompanion.insert(
      id: Value(_int(json['id'])!),
      code: Value(_string(json['code'])),
      name: _string(json['name']) ?? '이름 없는 항목',
      isBuiltIn: Value(_bool(json['is_built_in'])),
      defaultDistanceInterval: Value(_int(json['default_distance_interval'])),
      defaultTimeIntervalMonths: Value(
        _int(json['default_time_interval_months']),
      ),
    );

Map<String, Object?> settingToJson(VehicleMaintenanceSetting row) => {
  'vehicle_id': row.vehicleId,
  'maintenance_type_id': row.maintenanceTypeId,
  'distance_interval': row.distanceInterval,
  'time_interval_months': row.timeIntervalMonths,
  'notification_enabled': row.notificationEnabled,
};

VehicleMaintenanceSettingsCompanion settingFromJson(
  Map<String, Object?> json,
) => VehicleMaintenanceSettingsCompanion.insert(
  vehicleId: _int(json['vehicle_id'])!,
  maintenanceTypeId: _int(json['maintenance_type_id'])!,
  distanceInterval: Value(_int(json['distance_interval'])),
  timeIntervalMonths: Value(_int(json['time_interval_months'])),
  notificationEnabled: Value(_bool(json['notification_enabled'], orElse: true)),
);

Map<String, Object?> recordToJson(MaintenanceRecord row) => {
  'id': row.id,
  'vehicle_id': row.vehicleId,
  'maintenance_type_id': row.maintenanceTypeId,
  'maintenance_date': row.maintenanceDate.toIso8601String(),
  'mileage': row.mileage,
  'cost': row.cost,
  'shop_name': row.shopName,
  'memo': row.memo,
  'created_at': row.createdAt.toIso8601String(),
  'updated_at': row.updatedAt.toIso8601String(),
  // receiptAssetId is deliberately absent: the files are not carried, so a
  // restored record must not point at an attachment that cannot exist.
};

MaintenanceRecordsCompanion recordFromJson(Map<String, Object?> json) =>
    MaintenanceRecordsCompanion.insert(
      id: Value(_int(json['id'])!),
      vehicleId: _int(json['vehicle_id'])!,
      maintenanceTypeId: _int(json['maintenance_type_id'])!,
      maintenanceDate: _date(json['maintenance_date']),
      mileage: _int(json['mileage']) ?? 0,
      cost: Value(_int(json['cost'])),
      shopName: Value(_string(json['shop_name'])),
      memo: Value(_string(json['memo'])),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );

int? _int(Object? value) => switch (value) {
  final int number => number,
  final double number => number.round(),
  final String text => int.tryParse(text),
  _ => null,
};

String? _string(Object? value) {
  final text = value is String ? value.trim() : null;
  return (text == null || text.isEmpty) ? null : text;
}

bool _bool(Object? value, {bool orElse = false}) => switch (value) {
  final bool flag => flag,
  final int number => number != 0,
  'true' => true,
  'false' => false,
  _ => orElse,
};

DateTime _date(Object? value) =>
    DateTime.tryParse(value is String ? value : '') ??
    DateTime.fromMillisecondsSinceEpoch(0);
