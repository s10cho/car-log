import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../domain/picked_receipt.dart';

/// Chooses a receipt file from the camera, the photo library or the file system.
///
/// A seam rather than an abstraction for its own sake: widget tests have no
/// camera, and driving the platform picker from a test would prove nothing.
abstract interface class ReceiptPicker {
  /// Returns null when the user backs out.
  Future<PickedReceipt?> pick(ReceiptSource source);
}

class PlatformReceiptPicker implements ReceiptPicker {
  PlatformReceiptPicker({ImagePicker? images})
    : _images = images ?? ImagePicker();

  final ImagePicker _images;

  @override
  Future<PickedReceipt?> pick(ReceiptSource source) async {
    return switch (source) {
      ReceiptSource.camera => _fromImagePicker(ImageSource.camera),
      ReceiptSource.gallery => _fromImagePicker(ImageSource.gallery),
      ReceiptSource.file => _fromFilePicker(),
    };
  }

  Future<PickedReceipt?> _fromImagePicker(ImageSource source) async {
    final picked = await _images.pickImage(
      source: source,
      // Receipts only need to be readable, by a person or by an AI provider.
      // Full-resolution camera images would bloat backups for no gain.
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (picked == null) {
      return null;
    }
    return PickedReceipt(
      file: File(picked.path),
      fileName: picked.name,
      mimeType:
          picked.mimeType ?? mimeTypeForExtension(p.extension(picked.path)),
    );
  }

  Future<PickedReceipt?> _fromFilePicker() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'],
    );
    final path = picked?.path;
    if (path == null) {
      return null;
    }
    return PickedReceipt(
      file: File(path),
      fileName: picked!.name,
      mimeType: mimeTypeForExtension(p.extension(path)),
    );
  }
}

final receiptPickerProvider = Provider<ReceiptPicker>(
  (ref) => PlatformReceiptPicker(),
);
