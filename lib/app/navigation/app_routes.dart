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
  static const String vehicleListPath = '/vehicles';
  static const String vehicleListName = 'vehicles';

  static const String addVehiclePath = '/vehicle/new';
  static const String addVehicleName = 'addVehicle';

  static const String editVehiclePath = '/vehicle/:vehicleId/edit';
  static const String editVehicleName = 'editVehicle';

  static const String addMaintenancePath = '/maintenance/new';
  static const String addMaintenanceName = 'addMaintenance';

  static const String maintenanceIntervalPath =
      '/maintenance/interval/:vehicleId/:typeId';
  static const String maintenanceIntervalName = 'maintenanceInterval';

  static const String editMaintenancePath = '/maintenance/:recordId/edit';
  static const String editMaintenanceName = 'editMaintenance';

  static const String maintenanceDetailPath =
      '/maintenance/detail/:vehicleId/:typeId';
  static const String maintenanceDetailName = 'maintenanceDetail';

  static const String reminderSettingsPath = '/settings/reminders';
  static const String reminderSettingsName = 'reminderSettings';

  static const String maintenanceTypesPath = '/maintenance/types';
  static const String maintenanceTypesName = 'maintenanceTypes';
}
