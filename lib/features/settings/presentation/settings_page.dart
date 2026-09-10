import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';

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
