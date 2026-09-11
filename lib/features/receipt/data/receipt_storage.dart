import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';

/// Where receipt files live inside the app documents directory.
const String receiptsDirectoryName = 'receipts';

/// Copies picked receipt files into the app's own storage and hands back the
/// **relative** path to record.
///
/// Absolute paths are never stored: on iOS the app container is re-created with
/// a new UUID on reinstall, so a path saved today can point nowhere tomorrow.
class ReceiptStorage {
  ReceiptStorage({Future<Directory> Function()? documentsDirectory, Uuid? uuid})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory,
      _uuid = uuid ?? const Uuid();

  final Future<Directory> Function() _documentsDirectory;
  final Uuid _uuid;

  /// Copies [source] in and returns its path relative to the documents
  /// directory, keeping the original extension so the file stays openable.
  Future<String> save(File source) async {
    try {
      final root = await _documentsDirectory();
      final directory = Directory(p.join(root.path, receiptsDirectoryName));
      await directory.create(recursive: true);

      final extension = p.extension(source.path);
      final name = '${_uuid.v4()}$extension';
      await source.copy(p.join(directory.path, name));

      return p.join(receiptsDirectoryName, name);
    } on Object catch (error, stackTrace) {
      throw ReceiptStorageException(
        'Failed to store receipt file',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Turns a stored relative path back into a file for this install.
  Future<File> resolve(String relativePath) async {
    final root = await _documentsDirectory();
    return File(p.join(root.path, relativePath));
  }

  /// Removes a stored file. A missing file is not an error — the record it
  /// belonged to is going away either way.
  Future<void> delete(String relativePath) async {
    try {
      final file = await resolve(relativePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (error, stackTrace) {
      throw ReceiptStorageException(
        'Failed to delete receipt file',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final receiptStorageProvider = Provider<ReceiptStorage>(
  (ref) => ReceiptStorage(),
);
