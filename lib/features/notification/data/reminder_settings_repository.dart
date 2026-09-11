import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/app_preferences_repository.dart';
import '../domain/reminder_plan.dart';

const String _enabledKey = 'reminders_enabled';
const String _leadDaysKey = 'reminders_lead_days';
const String _hourKey = 'reminders_hour';

/// Stores the user's reminder preferences in the app-level key/value table.
class ReminderSettingsRepository {
  const ReminderSettingsRepository(this._preferences);

  final AppPreferencesRepository _preferences;

  /// Reminders are off until the user turns them on: notification permission
  /// should be asked for with a reason, not at first launch.
  static const ReminderSettings defaults = ReminderSettings(enabled: false);

  Future<ReminderSettings> read() async {
    final enabled = await _preferences.read(_enabledKey);
    final leadDays = await _preferences.read(_leadDaysKey);
    final hour = await _preferences.read(_hourKey);

    return ReminderSettings(
      enabled: enabled == 'true',
      leadDays: int.tryParse(leadDays ?? '') ?? defaults.leadDays,
      hourOfDay: int.tryParse(hour ?? '') ?? defaults.hourOfDay,
    );
  }

  Future<void> write(ReminderSettings settings) async {
    await _preferences.write(_enabledKey, '${settings.enabled}');
    await _preferences.write(_leadDaysKey, '${settings.leadDays}');
    await _preferences.write(_hourKey, '${settings.hourOfDay}');
  }

  /// Emits whenever any of the three preferences change.
  Stream<ReminderSettings> watch() async* {
    yield await read();
    await for (final _ in _preferences.watch(_enabledKey).skip(1)) {
      yield await read();
    }
  }
}

final reminderSettingsRepositoryProvider = Provider<ReminderSettingsRepository>(
  (ref) =>
      ReminderSettingsRepository(ref.watch(appPreferencesRepositoryProvider)),
);

final reminderSettingsProvider = StreamProvider<ReminderSettings>(
  (ref) => ref.watch(reminderSettingsRepositoryProvider).watch(),
);
