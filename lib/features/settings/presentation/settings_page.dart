import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/navigation/app_routes.dart';
import '../data/theme_settings_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final themeMode =
        ref.watch(themeModeProvider).value ??
        ThemeSettingsRepository.defaultMode;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.reminderSettingsName),
          ),
          ListTile(
            leading: Icon(_themeIcon(themeMode)),
            title: const Text('화면 테마'),
            subtitle: Text(_themeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickThemeMode(context, ref, themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: const Text('차량 연동'),
            subtitle: const Text('연동되지 않음 · 주행거리 직접 입력'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.vehicleIntegrationName),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('AI 영수증 분석'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.aiSettingsName),
          ),
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('정비 항목'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.maintenanceTypesName),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('백업 / 복원'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.backupName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.privacyName),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.aboutName),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('환경'),
            subtitle: Text(config.environment.key),
            leading: const Icon(Icons.tune_outlined),
          ),
          ListTile(
            title: const Text('앱 이름'),
            subtitle: Text(config.appName),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => '라이트',
  ThemeMode.dark => '다크',
  ThemeMode.system => '시스템 설정 따르기',
};

IconData _themeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
  ThemeMode.system => Icons.brightness_auto_outlined,
};

Future<void> _pickThemeMode(
  BuildContext context,
  WidgetRef ref,
  ThemeMode current,
) async {
  final picked = await showDialog<ThemeMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('화면 테마'),
      children: [
        // Listed in the order a user reaches for them, not enum order, which
        // would put "follow the system" first.
        for (final mode in const [
          ThemeMode.light,
          ThemeMode.dark,
          ThemeMode.system,
        ])
          ListTile(
            leading: Icon(_themeIcon(mode)),
            title: Text(_themeLabel(mode)),
            // A check on the current choice rather than a radio: the list is
            // the choice, and one tap both picks and closes.
            trailing: mode == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(mode),
          ),
      ],
    ),
  );
  if (picked == null || picked == current) {
    return;
  }
  await ref.read(themeSettingsRepositoryProvider).write(picked);
}
