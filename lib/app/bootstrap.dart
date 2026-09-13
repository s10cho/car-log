import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../core/logging/app_logger.dart';
import '../features/garage/presentation/car_scene.dart';
import 'app.dart';
import 'config/app_config.dart';

final _log = Logger('bootstrap');

/// Single entry point for every flavour of the app.
///
/// Installs the global error handlers before the first frame so that a failure
/// during startup is reported rather than silently swallowed.
Future<void> bootstrap({AppConfig? config}) async {
  final resolved = config ?? AppConfig.fromDartDefine();

  WidgetsFlutterBinding.ensureInitialized();
  configureLogging(resolved);
  installErrorHandlers();

  _log.info('Starting ${resolved.appName} (${resolved.environment.key})');

  // Starts the 3D engine loading now, so the garage has a car to show the
  // moment it opens rather than a beat later. Never awaited: the app opens at
  // the same speed whether or not the device can render 3D at all.
  unawaited(warmUpCarScene());

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(resolved)],
      child: const CarLogApp(),
    ),
  );
}

/// Routes framework and isolate level errors into the app logger.
void installErrorHandlers() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    _log.severe(details.summary.toString(), details.exception, details.stack);
    previous?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _log.severe('Uncaught platform error', error, stackTrace);
    return !kDebugMode;
  };
}
