import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notification/presentation/reminder_sync.dart';
import '../features/settings/data/theme_settings_repository.dart';
import 'config/app_config.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';

class CarLogApp extends ConsumerWidget {
  const CarLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return ReminderSync(
      child: MaterialApp.router(
        title: config.appName,
        debugShowCheckedModeBanner: config.isDev,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // The stored choice arrives a frame or two after launch; until then
        // the default light theme is shown rather than the system's, so the
        // app never flashes dark on its way to being light.
        themeMode:
            ref.watch(themeModeProvider).value ??
            ThemeSettingsRepository.defaultMode,
        routerConfig: ref.watch(routerProvider),
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
