import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version and licence information.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 정보')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return ListView(
            children: [
              ListTile(
                title: const Text('앱'),
                subtitle: Text(info?.appName ?? '차계부'),
              ),
              ListTile(
                title: const Text('버전'),
                subtitle: Text(
                  info == null
                      ? '확인 중…'
                      : '${info.version} (${info.buildNumber})',
                ),
              ),
              ListTile(
                title: const Text('오픈소스 라이선스'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: info?.appName ?? '차계부',
                  applicationVersion: info?.version,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
