import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../app/config/app_config.dart';

StreamSubscription<LogRecord>? _subscription;

/// Wires the root logger to the platform log sink.
///
/// Never pass credentials through this: AI API keys, OAuth tokens and raw
/// receipt contents must not reach any log record.
void configureLogging(AppConfig config) {
  Logger.root.level = config.verboseLogging ? Level.ALL : Level.WARNING;
  _subscription?.cancel();
  _subscription = Logger.root.onRecord.listen(_emit);
}

/// Detaches the sink. Used by tests so log listeners do not leak between cases.
Future<void> resetLogging() async {
  await _subscription?.cancel();
  _subscription = null;
}

void _emit(LogRecord record) {
  if (kReleaseMode && record.level < Level.WARNING) {
    return;
  }
  developer.log(
    record.message,
    time: record.time,
    level: record.level.value,
    name: record.loggerName,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}
