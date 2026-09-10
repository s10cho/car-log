import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time environment, selected with `--dart-define=APP_ENV=dev|production`.
///
/// Only two environments exist on purpose; see `docs/decisions.md`.
enum AppEnvironment {
  dev('dev'),
  production('production');

  const AppEnvironment(this.key);

  final String key;

  static AppEnvironment fromKey(String key) {
    for (final environment in AppEnvironment.values) {
      if (environment.key == key) {
        return environment;
      }
    }
    throw ArgumentError.value(key, 'key', 'Unknown APP_ENV');
  }
}

/// Everything that differs between DEV and PRODUCTION builds.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.databaseName,
    required this.verboseLogging,
  });

  /// Reads `APP_ENV` from the compile-time environment, defaulting to DEV.
  factory AppConfig.fromDartDefine() {
    const key = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    return AppConfig.of(AppEnvironment.fromKey(key));
  }

  factory AppConfig.of(AppEnvironment environment) => switch (environment) {
    AppEnvironment.dev => const AppConfig(
      environment: AppEnvironment.dev,
      appName: 'Car Log DEV',
      databaseName: 'car_log_dev',
      verboseLogging: true,
    ),
    AppEnvironment.production => const AppConfig(
      environment: AppEnvironment.production,
      appName: 'Car Log',
      databaseName: 'car_log',
      verboseLogging: false,
    ),
  };

  final AppEnvironment environment;
  final String appName;

  /// File name of the local Drift database. DEV and PRODUCTION never share one.
  final String databaseName;
  final bool verboseLogging;

  bool get isDev => environment == AppEnvironment.dev;
}

/// Always overridden in `bootstrap()`; reading it unbound is a programming error.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);
