import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of the screen tour: writes each screenshot the tour takes to
/// `$SCREENSHOT_DIR` (default `build/screenshots`).
///
/// ```bash
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/screen_tour_test.dart -d "iPhone 16 Pro"
/// ```
Future<void> main() {
  final directory = Directory(
    Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots',
  )..createSync(recursive: true);

  return integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      File('${directory.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
