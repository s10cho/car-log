import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/home_page.dart';
import '../../features/maintenance/presentation/add_maintenance_page.dart';
import '../../features/maintenance/presentation/maintenance_interval_page.dart';
import '../../features/maintenance/presentation/record_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/vehicle/presentation/vehicle_registration_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Created per router rather than as a top-level global: a global key would
  // be registered twice whenever two routers exist at once, as they do
  // between test cases.
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.homePath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homePath,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recordsPath,
                name: AppRoutes.recordsName,
                builder: (context, state) => const RecordPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settingsPath,
                name: AppRoutes.settingsName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addVehiclePath,
        name: AppRoutes.addVehicleName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VehicleRegistrationPage(),
      ),
      GoRoute(
        path: AppRoutes.addMaintenancePath,
        name: AppRoutes.addMaintenanceName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddMaintenancePage(),
      ),
      GoRoute(
        path: AppRoutes.maintenanceIntervalPath,
        name: AppRoutes.maintenanceIntervalName,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => MaintenanceIntervalPage(
          vehicleId: int.parse(state.pathParameters['vehicleId']!),
        ),
      ),
    ],
  );
});
