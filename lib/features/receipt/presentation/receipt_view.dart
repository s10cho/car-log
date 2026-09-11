import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/receipt_storage.dart';

/// Shows an attached receipt, full screen.
///
/// Images are rendered; anything else (a PDF from a workshop, say) is named
/// rather than previewed — the app carries no document renderer, and claiming
/// to show a file it cannot would be worse than saying so.
class ReceiptViewPage extends ConsumerWidget {
  const ReceiptViewPage({required this.asset, super.key});

  final ReceiptAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(asset.fileName)),
      body: Center(
        child: FutureBuilder<File>(
          future: ref.watch(receiptStorageProvider).resolve(asset.relativePath),
          builder: (context, snapshot) {
            final file = snapshot.data;
            if (file == null) {
              return const CircularProgressIndicator();
            }
            if (!file.existsSync()) {
              return const _Missing();
            }
            if (!asset.mimeType.startsWith('image/')) {
              return _NoPreview(asset: asset);
            }
            return InteractiveViewer(
              maxScale: 5,
              child: Image.file(
                file,
                errorBuilder: (context, _, _) => const _Missing(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('영수증 파일을 찾을 수 없습니다.', textAlign: TextAlign.center),
    );
  }
}

class _NoPreview extends StatelessWidget {
  const _NoPreview({required this.asset});

  final ReceiptAsset asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(asset.fileName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '이미지가 아닌 파일은 앱에서 미리 볼 수 없습니다. 파일은 그대로 보관됩니다.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
