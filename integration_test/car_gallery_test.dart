import 'package:car_log/features/garage/domain/car_body_style.dart';
import 'package:car_log/features/garage/domain/car_paint_color.dart';
import 'package:car_log/features/garage/presentation/car_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Photographs every car in the garage, one per screenshot.
///
/// Not an assertion suite. Models come from different authors in different
/// units and pointing in different directions, and the only way to know a
/// model is the right size and facing the camera is to look at it. Run with
/// `flutter drive` (see test_driver/integration_test.dart) after changing the
/// model set.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final style in CarBodyStyle.values) {
    testWidgets('renders ${style.id}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CarScene(
                style: style,
                color: CarPaintColor.red,
                height: 360,
              ),
            ),
          ),
        ),
      );

      // No pumpAndSettle: the scene animates forever, so settling never
      // finishes. A fixed number of frames is enough for a screenshot.
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await binding.takeScreenshot('car-${style.id}');
    });
  }
}
