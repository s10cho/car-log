import 'dart:io';

import 'package:meta/meta.dart';

/// Where a receipt came from.
enum ReceiptSource { camera, gallery, file }

/// A file the user chose, before it is copied into the app's storage.
@immutable
class PickedReceipt {
  const PickedReceipt({
    required this.file,
    required this.fileName,
    required this.mimeType,
  });

  final File file;
  final String fileName;
  final String mimeType;

  bool get isImage => mimeType.startsWith('image/');
}

/// Maps a file extension to a MIME type.
///
/// A tiny table rather than a package: the picker only offers images and PDFs,
/// and everything else is recorded honestly as unknown.
String mimeTypeForExtension(String extension) {
  return switch (extension.toLowerCase().replaceFirst('.', '')) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
