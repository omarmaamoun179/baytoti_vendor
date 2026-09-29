import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import 'splash_timeline.dart';

/// The splash's mark at [seconds]: the house drawn stroke by stroke, the
/// shop awning dropping over the door, the leaf and the bird popping in, and
/// two rings widening behind it all.
///
/// [size] is the design's 190 box; the house takes its 112×100 middle, and
/// the rings start inside it and grow past it.
class SplashMark extends StatelessWidget {
  final double seconds;
  final double size;

  const SplashMark({super.key, required this.seconds, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return CustomPaint(
      size: Size.square(size),
      painter: SplashMarkPainter(
        seconds: seconds,
        stroke: p.onAccent,
        leaf: p.amberBg,
        bird: p.accent,
      ),
    );
  }
}

class SplashMarkPainter extends CustomPainter {
  /// The mark's own viewBox, and the box it sits in.
  static const Size viewBox = Size(96, 86);
  static const double box = 190;
  static const double markHeight = 100;

  final double seconds;
  final Color stroke;
  final Color leaf;
  final Color bird;

  SplashMarkPainter({
    required this.seconds,
    required this.stroke,
    required this.leaf,
    required this.bird,
  });

  /// `M14 40L48 13l34 27`
  static final Path roof = Path()
    ..moveTo(14, 40)
    ..lineTo(48, 13)
    ..lineTo(82, 40);

  /// `M21 38v32h54V38`
  static final Path walls = Path()
    ..moveTo(21, 38)
    ..lineTo(21, 70)
    ..lineTo(75, 70)
    ..lineTo(75, 38);

  /// `M40 70V61h16v9` — lower than the customer app's door, under the
  /// awning.
  static final Path door = Path()
    ..moveTo(40, 70)
    ..lineTo(40, 61)
    ..lineTo(56, 61)
    ..lineTo(56, 70);

  /// `M30 44h36v5c0 2.8-2 4.5-4.5 4.5S57 51.8 57 49…S30 51.8 30 49z` — a
  /// strip with four scallops, each 9 wide, drawn right to left.
  static final Path awning = () {
    final path = Path()
      ..moveTo(30, 44)
      ..lineTo(66, 44)
      ..lineTo(66, 49);
    for (var x = 66.0; x > 30; x -= 9) {
      path
        ..cubicTo(x, 51.8, x - 2, 53.5, x - 4.5, 53.5)
        ..cubicTo(x - 7, 53.5, x - 9, 51.8, x - 9, 49);
    }
    return path..close();
  }();

  /// `M44 30c0-7 5-12 11-13-1 8-5 12-11 13z`
  static final Path leafShape = Path()
    ..moveTo(44, 30)
    ..cubicTo(44, 23, 49, 18, 55, 17)
    ..cubicTo(54, 25, 50, 29, 44, 30)
    ..close();

  /// `M62 24c3.6 0 6 2.4 6 5.6…z`
  static final Path birdShape = Path()
    ..moveTo(62, 24)
    ..cubicTo(65.6, 24, 68, 26.4, 68, 29.6)
    ..cubicTo(68, 33, 65.2, 36, 61.6, 36)
    ..cubicTo(60.4, 36, 59.2, 35.6, 58.4, 35)
    ..lineTo(55, 36.4)
    ..lineTo(56.2, 33.2)
    ..cubicTo(55.6, 32.2, 55.2, 31, 55.2, 29.8)
    ..cubicTo(55.2, 26.6, 58.4, 24, 62, 24)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / box;
    for (final start in SplashTimeline.ringsAt) {
      _ring(canvas, size, unit, start);
    }

    final scale = unit * markHeight / viewBox.height;
    canvas
      ..save()
      ..translate(
        (size.width - viewBox.width * scale) / 2,
        (size.height - viewBox.height * scale) / 2,
      )
      ..scale(scale);

    _draw(canvas, roof, start: SplashTimeline.roofAt, width: 5.5);
    _draw(canvas, walls, start: SplashTimeline.wallsAt, width: 5.5);
    _draw(canvas, door, start: SplashTimeline.doorAt, width: 5);
    _drop(canvas, awning, stroke, start: SplashTimeline.awningAt);
    _pop(canvas, leafShape, leaf, start: SplashTimeline.leafAt);
    _pop(canvas, birdShape, bird, start: SplashTimeline.birdAt);

    canvas.restore();
  }

  /// `btRing`: from .55 to 1.6 times the box, easing out, fading in over
  /// the first 30 % and out over the rest.
  void _ring(Canvas canvas, Size size, double unit, double start) {
    if (seconds < start) return;

    final phase =
        ((seconds - start) % SplashTimeline.ringFor) / SplashTimeline.ringFor;
    final opacity = phase < .3
        ? Curves.easeOut.transform(phase / .3)
        : 1 - Curves.easeOut.transform((phase - .3) / .7);
    final grow = .55 + (1.6 - .55) * Curves.easeOut.transform(phase);
    final width = 1.5 * unit * grow;

    canvas.drawCircle(
      size.center(Offset.zero),
      (size.width / 2) * grow - width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = stroke.withValues(alpha: .22 * opacity.clamp(0.0, 1.0)),
    );
  }

  /// `btDraw`: the stroke laid down from its first point to its last.
  void _draw(
    Canvas canvas,
    Path path, {
    required double start,
    required double width,
  }) {
    final drawn = SplashTimeline.eased(
      SplashTimeline.draw,
      seconds,
      start,
      SplashTimeline.drawFor,
    );
    if (drawn <= 0) return;

    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * drawn), paint);
    }
  }

  /// The awning: grown down from its top edge, springing past its length.
  void _drop(Canvas canvas, Path path, Color color, {required double start}) {
    final grown = SplashTimeline.eased(
      SplashTimeline.drop,
      seconds,
      start,
      SplashTimeline.dropFor,
    );
    if (grown <= 0) return;

    final top = path.getBounds().topCenter;
    canvas
      ..save()
      ..translate(top.dx, top.dy)
      ..scale(1, grown)
      ..translate(-top.dx, -top.dy)
      ..drawPath(path, Paint()..color = color)
      ..restore();
  }

  /// The leaf and the bird: grown from their centres, springing past size.
  void _pop(Canvas canvas, Path path, Color color, {required double start}) {
    final scale = SplashTimeline.eased(
      SplashTimeline.pop,
      seconds,
      start,
      SplashTimeline.popFor,
    );
    if (scale <= 0) return;

    final center = path.getBounds().center;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(scale)
      ..translate(-center.dx, -center.dy)
      ..drawPath(path, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(SplashMarkPainter old) =>
      old.seconds != seconds ||
      old.stroke != stroke ||
      old.leaf != leaf ||
      old.bird != bird;
}
