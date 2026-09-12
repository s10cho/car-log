import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A brief burst of confetti over the whole screen.
///
/// Saving a maintenance record is the moment the app exists for, and it used to
/// end with a screen quietly popping. A second of celebration costs nothing and
/// makes finishing the chore feel like finishing something.
///
/// Drawn rather than pulled from an animation package: a few dozen rectangles
/// need no dependency, no asset, and no extra megabyte in the download.
///
/// Call this **before** popping the screen that triggered it. The burst goes
/// into the root overlay, which outlives the route, but reading the overlay off
/// a context that has already been popped throws.
void celebrate(BuildContext context, {String? message}) {
  unawaited(HapticFeedback.mediumImpact());

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: _ConfettiBurst(message: message, onDone: () => entry.remove()),
    ),
  );
  overlay.insert(entry);
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({required this.onDone, this.message});

  final VoidCallback onDone;

  /// Shown near the top rather than in a SnackBar: a SnackBar covers the
  /// button the user just came from, and this is a congratulation, not a
  /// notice that needs an action.
  final String? message;

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  late final List<_Piece> _pieces = _makePieces();

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDone();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Piece> _makePieces() {
    // Seeded so the burst looks the same in a screenshot test run twice.
    final random = math.Random(7);
    return [
      for (var i = 0; i < 46; i++)
        _Piece(
          x: random.nextDouble(),
          delay: random.nextDouble() * 0.25,
          drift: random.nextDouble() * 0.3 - 0.15,
          spin: random.nextDouble() * 8 - 4,
          size: 6 + random.nextDouble() * 7,
          hue: random.nextInt(4),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.primaryContainer,
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ConfettiPainter(
                pieces: _pieces,
                progress: _controller.value,
                palette: palette,
              ),
            ),
          ),
          if (widget.message case final String text)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 24,
              right: 24,
              child: Opacity(
                opacity: _bannerOpacity(_controller.value),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onInverseSurface),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Fades in quickly, holds, then fades out with the confetti.
  static double _bannerOpacity(double progress) {
    if (progress < 0.12) {
      return progress / 0.12;
    }
    if (progress > 0.8) {
      return ((1 - progress) / 0.2).clamp(0.0, 1.0);
    }
    return 1;
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.drift,
    required this.spin,
    required this.size,
    required this.hue,
  });

  final double x;
  final double delay;
  final double drift;
  final double spin;
  final double size;
  final int hue;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.palette,
  });

  final List<_Piece> pieces;
  final double progress;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final local = ((progress - piece.delay) / (1 - piece.delay)).clamp(
        0.0,
        1.0,
      );
      if (local <= 0) {
        continue;
      }

      // Falls with a little acceleration and fades out at the end.
      final y = size.height * (local * local * 1.15 - 0.1);
      final x = size.width * (piece.x + piece.drift * local);
      final opacity = local > 0.75 ? (1 - local) / 0.25 : 1.0;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.spin * local);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.55,
        ),
        Paint()
          ..color = palette[piece.hue % palette.length].withValues(
            alpha: opacity.clamp(0.0, 1.0),
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
