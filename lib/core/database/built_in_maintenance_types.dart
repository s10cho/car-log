import 'package:meta/meta.dart';

/// A maintenance item the app ships with.
@immutable
class BuiltInMaintenanceType {
  const BuiltInMaintenanceType({
    required this.code,
    required this.name,
    this.distanceInterval,
    this.timeIntervalMonths,
  });

  final String code;
  final String name;
  final int? distanceInterval;
  final int? timeIntervalMonths;
}

/// Stable code of 엔진오일, the item the first-run experience is built around.
const String engineOilTypeCode = 'engine_oil';

/// The items every vehicle starts with.
///
/// The intervals are **general recommendations, not manufacturer figures.**
/// Real intervals vary by car, oil grade and driving conditions, so every one
/// of these is editable per vehicle — see `VehicleMaintenanceSettings`. Only
/// 엔진오일 and 와이퍼 come from the product spec; the rest are the commonly
/// quoted ranges for passenger cars in Korea, chosen so that a new user has a
/// sensible starting point rather than an empty form.
const List<BuiltInMaintenanceType> builtInMaintenanceTypes = [
  BuiltInMaintenanceType(
    code: engineOilTypeCode,
    name: '엔진오일',
    distanceInterval: 10000,
    timeIntervalMonths: 12,
  ),
  BuiltInMaintenanceType(
    code: 'oil_filter',
    name: '오일필터',
    distanceInterval: 10000,
    timeIntervalMonths: 12,
  ),
  BuiltInMaintenanceType(
    code: 'air_filter',
    name: '에어필터',
    distanceInterval: 20000,
    timeIntervalMonths: 12,
  ),
  BuiltInMaintenanceType(
    code: 'cabin_filter',
    name: '에어컨필터',
    distanceInterval: 15000,
    timeIntervalMonths: 6,
  ),
  BuiltInMaintenanceType(code: 'wiper', name: '와이퍼', timeIntervalMonths: 12),
  BuiltInMaintenanceType(
    code: 'tire',
    name: '타이어',
    distanceInterval: 50000,
    timeIntervalMonths: 48,
  ),
  BuiltInMaintenanceType(
    code: 'brake_pad',
    name: '브레이크 패드',
    distanceInterval: 40000,
  ),
  BuiltInMaintenanceType(
    code: 'brake_fluid',
    name: '브레이크 오일',
    distanceInterval: 40000,
    timeIntervalMonths: 24,
  ),
  BuiltInMaintenanceType(
    code: 'battery',
    name: '배터리',
    distanceInterval: 60000,
    timeIntervalMonths: 36,
  ),
  BuiltInMaintenanceType(
    code: 'coolant',
    name: '냉각수',
    distanceInterval: 100000,
    timeIntervalMonths: 48,
  ),
];
