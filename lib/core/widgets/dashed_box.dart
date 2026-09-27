import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// A rounded box with a dashed 1px border — the design's "add a photo"
/// tiles (`border: 1px dashed`), which Flutter's borders cannot draw.
class DashedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  const DashedBox({
    super.key,
    required this.child,
    required this.color,
    required this.radius,
    this.dash = 4,
    this.gap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        dash: dash,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(.5),
        Radius.circular(radius),
      ));

    for (final PathMetric metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}
