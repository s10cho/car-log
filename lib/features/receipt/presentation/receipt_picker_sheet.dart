import 'package:flutter/material.dart';

import '../domain/picked_receipt.dart';

/// Asks where the receipt should come from.
Future<ReceiptSource?> showReceiptSourceSheet(BuildContext context) {
  return showModalBottomSheet<ReceiptSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('촬영'),
            onTap: () => Navigator.of(context).pop(ReceiptSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('앨범에서 선택'),
            onTap: () => Navigator.of(context).pop(ReceiptSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('파일에서 선택'),
            onTap: () => Navigator.of(context).pop(ReceiptSource.file),
          ),
        ],
      ),
    ),
  );
}
