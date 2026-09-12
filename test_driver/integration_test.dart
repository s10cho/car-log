import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver for integration tests that capture screenshots.
///
/// Screenshots land in `build/screenshots/`, which is how UI work gets reviewed
/// without a person holding the phone:
///
///     flutter drive --driver=test_driver/integration_test.dart \
///       --target=integration_test/screenshots_test.dart -d <device>
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final directory = Directory('build/screenshots')
        ..createSync(recursive: true);
      File('${directory.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
