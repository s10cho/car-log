import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/app_formats.dart';
import '../../receipt/data/receipt_picker.dart';
import '../../receipt/domain/picked_receipt.dart';
import '../data/backup_repository.dart';
import '../domain/backup_document.dart';

/// Exports the user's data to a file, and puts one back.
///
/// The user owns their data: an export is a plain JSON file they can read,
/// keep anywhere and move to another phone without going through us.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('백업')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('백업 내보내기'),
            subtitle: const Text('파일로 저장하거나 iCloud·Google Drive 로 보냅니다'),
            enabled: !_busy,
            onTap: _busy ? null : _export,
          ),
          ListTile(
            leading: const Icon(Icons.restore_page_outlined),
            title: const Text('백업 복원하기'),
            subtitle: const Text('지금 데이터를 백업 파일의 내용으로 바꿉니다'),
            enabled: !_busy,
            onTap: _busy ? null : _import,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '백업에는 차량, 정비 기록, 정비 항목, 교체주기, 알림 설정이 들어갑니다.\n\n'
              '영수증 사진은 들어가지 않습니다. 파일이 너무 커져서 옮기기 어려운 백업이 되기 '
              '때문입니다. 사진은 기기에 그대로 남아 있습니다.\n\n'
              'AI API 키처럼 보안 저장소에 있는 정보도 들어가지 않습니다. 복원한 뒤에는 '
              'AI 를 다시 연결해 주세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final info = await PackageInfo.fromPlatform();
      final file = await ref
          .read(backupRepositoryProvider)
          .exportToFile(appVersion: '${info.version}+${info.buildNumber}');

      if (!mounted) {
        return;
      }
      setState(() => _busy = false);

      // The system share sheet is how a file reaches iCloud Drive, Google
      // Drive, email or anywhere else — one path instead of an integration per
      // destination, and nothing for this app to authenticate against.
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Car Log 백업',
        ),
      );
    } on AppException catch (error) {
      _report(error.message);
    } on Object {
      _report('백업 파일을 만들지 못했습니다.');
    }
  }

  Future<void> _import() async {
    final picked = await ref
        .read(receiptPickerProvider)
        .pick(ReceiptSource.file);
    if (picked == null || !mounted) {
      return;
    }

    setState(() => _busy = true);
    BackupDocument document;
    try {
      final text = await File(picked.file.path).readAsString();
      document = parseBackupDocument(jsonDecode(text) as Object?);
    } on BackupFormatException catch (error) {
      _report(error.message);
      return;
    } on Object {
      _report('백업 파일을 읽지 못했습니다.');
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _busy = false);

    // Restoring throws away what is on the device. Say what is coming and what
    // is going before doing it.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 백업으로 되돌릴까요?'),
        content: Text(
          '${formatDate(document.exportedAt)} 백업\n'
          '차량 ${document.vehicleCount}대 · 정비 기록 ${document.recordCount}건\n\n'
          '지금 기기에 있는 차량과 정비 기록은 모두 지워지고 백업의 내용으로 바뀝니다. '
          '되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('복원'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(backupRepositoryProvider).restore(document);
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('백업을 복원했습니다.')));
      }
    } on AppException catch (error) {
      _report(error.message);
    } on Object {
      _report('백업을 복원하지 못했습니다.');
    }
  }

  void _report(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
