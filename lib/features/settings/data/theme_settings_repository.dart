import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences_repository.dart';

const String _themeModeKey = 'theme_mode';

/// Stores the user's light/dark choice in the app-level key/value table.
///
/// The default is light rather than "follow the system": the garage is a
/// bright room, and a phone left in dark mode would otherwise open the app
/// dark without the user ever having asked for it. Following the system is
/// still on offer — as a choice.
class ThemeSettingsRepository {
  const ThemeSettingsRepository(this._preferences);

  final AppPreferencesRepository _preferences;

  static const ThemeMode defaultMode = ThemeMode.light;

  Future<ThemeMode> read() async =>
      parse(await _preferences.read(_themeModeKey));

  Future<void> write(ThemeMode mode) =>
      _preferences.write(_themeModeKey, mode.name);

  /// Emits the stored mode and every later change to it.
  Stream<ThemeMode> watch() => _preferences.watch(_themeModeKey).map(parse);

  /// An unknown value — a mode written by a newer build — reads as the
  /// default rather than throwing the app into a broken theme.
  static ThemeMode parse(String? value) => switch (value) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    _ => defaultMode,
  };
}

final themeSettingsRepositoryProvider = Provider<ThemeSettingsRepository>(
  (ref) => ThemeSettingsRepository(ref.watch(appPreferencesRepositoryProvider)),
);

final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(themeSettingsRepositoryProvider).watch(),
);
