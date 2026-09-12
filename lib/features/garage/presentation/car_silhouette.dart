import 'package:flutter/material.dart';

import '../domain/car_body_style.dart';

/// A drawn car, used where the 3D model cannot be.
///
/// Not a placeholder box: if a device cannot render the model, the screen
/// should still look finished. The shape follows the chosen body style so the
/// user's car remains recognisably theirs.
class CarSilhouette extends StatelessWidget {
  const CarSilhouette({required this.style, this.height = 200, super.key});

  final CarBodyStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      // Width as well as height: a CustomPaint with no child takes its size
      // from its constraints, and a loose parent would leave it at zero.
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _CarPainter(
          style: style,
          body: scheme.primary,
          glass: scheme.surfaceContainerHighest,
          tyre: scheme.onSurfaceVariant,
          ground: scheme.shadow.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _CarPainter extends CustomPainter {
  const _CarPainter({
    required this.style,
    required this.body,
    required this.glass,
    required this.tyre,
    required this.ground,
  });

  final CarBodyStyle style;
  final Color body;
  final Color glass;
  final Color tyre;
  final Color ground;

  /// Proportions per body style, as fractions of the drawing box.
  ({double roofStart, double roofEnd, double roofHeight, double length})
  get _shape => switch (style) {
    CarBodyStyle.sedanSports => (
      roofStart: 0.34,
      roofEnd: 0.62,
      roofHeight: 0.26,
      length: 0.92,
    ),
    CarBodyStyle.suv || CarBodyStyle.suvLuxury => (
      roofStart: 0.26,
      roofEnd: 0.74,
      roofHeight: 0.46,
      length: 0.88,
    ),
    CarBodyStyle.van || CarBodyStyle.delivery => (
      roofStart: 0.22,
      roofEnd: 0.84,
      roofHeight: 0.54,
      length: 0.94,
    ),
    CarBodyStyle.truck => (
      roofStart: 0.22,
      roofEnd: 0.5,
      roofHeight: 0.5,
      length: 0.94,
    ),
    _ => (roofStart: 0.3, roofEnd: 0.68, roofHeight: 0.34, length: 0.9),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape;
    final width = size.width * shape.length;
    final left = (size.width - width) / 2;
    final baseline = size.height * 0.74;
    final bodyHeight = size.height * 0.2;
    final roofTop =
        baseline - bodyHeight - size.height * shape.roofHeight * 0.5;

    // A soft ellipse stands in for a contact shadow and settles the car on a
    // surface rather than floating it.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, baseline + size.height * 0.06),
        width: width * 0.92,
        height: size.height * 0.1,
      ),
      Paint()..color = ground,
    );

    final cabin = Path()
      ..moveTo(left + width * shape.roofStart, baseline - bodyHeight)
      ..lineTo(left + width * (shape.roofStart + 0.06), roofTop)
      ..lineTo(left + width * (shape.roofEnd - 0.04), roofTop)
      ..lineTo(left + width * shape.roofEnd, baseline - bodyHeight)
      ..close();
    canvas.drawPath(cabin, Paint()..color = body);
    canvas.drawPath(
      cabin.shift(const Offset(0, 4)),
      Paint()..color = glass.withValues(alpha: 0.85),
    );
    canvas.drawPath(cabin, Paint()..color = body.withValues(alpha: 0.25));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - bodyHeight, width, bodyHeight),
        Radius.circular(bodyHeight * 0.3),
      ),
      Paint()..color = body,
    );

    final radius = size.height * 0.085;
    for (final position in [0.24, 0.76]) {
      canvas.drawCircle(
        Offset(left + width * position, baseline),
        radius,
        Paint()..color = tyre,
      );
      canvas.drawCircle(
        Offset(left + width * position, baseline),
        radius * 0.45,
        Paint()..color = glass,
      );
    }
  }

  @override
  bool shouldRepaint(_CarPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.body != body;
}
