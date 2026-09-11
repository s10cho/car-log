import 'dart:io';

import 'package:car_log/features/receipt/data/receipt_picker.dart';
import 'package:car_log/features/receipt/domain/picked_receipt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Stands in for the camera and the file system in widget tests.
class FakeReceiptPicker implements ReceiptPicker {
  final List<ReceiptSource> requested = [];

  /// What the next pick returns. Null means the user backed out.
  PickedReceipt? next;

  /// When set, picking throws — the plugin failing or permission being refused.
  Object? error;

  @override
  Future<PickedReceipt?> pick(ReceiptSource source) async {
    requested.add(source);
    if (error != null) {
      throw error!;
    }
    return next;
  }

  /// Builds a receipt backed by a real temporary file so widgets can read it.
  static PickedReceipt fileNamed(String name, [String contents = 'receipt']) {
    final directory = Directory.systemTemp.createTempSync('car_log_pick');
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final file = File(p.join(directory.path, name))
      ..writeAsStringSync(contents);
    return PickedReceipt(
      file: file,
      fileName: name,
      mimeType: mimeTypeForExtension(p.extension(name)),
    );
  }
}
