import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/navigation/app_routes.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
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
