/// Every route path and name in the app, in one place.
abstract final class AppRoutes {
  static const String homePath = '/home';
  static const String homeName = 'home';

  static const String recordsPath = '/records';
  static const String recordsName = 'records';

  static const String settingsPath = '/settings';
  static const String settingsName = 'settings';

  /// Full-screen forms live outside the bottom-navigation shell so they cover
  /// the whole screen while the user is filling them in.
  static const String addVehiclePath = '/vehicle/new';
  static const String addVehicleName = 'addVehicle';

  static const String addMaintenancePath = '/maintenance/new';
  static const String addMaintenanceName = 'addMaintenance';

  static const String maintenanceIntervalPath =
      '/maintenance/interval/:vehicleId';
  static const String maintenanceIntervalName = 'maintenanceInterval';
}
