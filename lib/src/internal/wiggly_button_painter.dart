import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints a rounded-rectangle button shape whose perimeter wiggles.
///
/// The fill is solid; the stroke is a sinusoidal perturbation of the
/// rounded-rect outline (offset along the outward normal).
class WigglyButtonPainter extends CustomPainter {
  WigglyButtonPainter({
    required this.phase,
    required this.fillColor,
    required this.strokeColor,
    required this.borderRadius,
    required this.waveAmplitude,
    required this.waveCount,
    required this.strokeWidth,
  });

  final double phase;
  final Color fillColor;
  final Color? strokeColor;
  final double borderRadius;
  final double waveAmplitude;
  final int waveCount;
  final double strokeWidth;

  static const int _segments = 240;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(borderRadius, math.min(size.width, size.height) / 2);
    final basePath = _roundedRectPath(size, radius);
    final wigglyPath = _wigglyOutline(basePath, size);

    canvas.drawPath(wigglyPath, Paint()..color = fillColor);

    if (strokeColor != null && strokeWidth > 0) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor!;
      canvas.drawPath(wigglyPath, stroke);
    }
  }

  Path _roundedRectPath(Size size, double radius) {
    return Path()
      ..addRRect(
        RRect.fromLTRBR(
          0,
          0,
          size.width,
          size.height,
          Radius.circular(radius),
        ),
      );
  }

  Path _wigglyOutline(Path basePath, Size size) {
    final metrics = basePath.computeMetrics().toList();
    if (metrics.isEmpty) return basePath;
    final metric = metrics.first;
    final length = metric.length;
    if (length <= 0) return basePath;

    final path = Path();
    for (var i = 0; i <= _segments; i++) {
      final t = i / _segments;
      final distance = t * length;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;

      final pos = tangent.position;
      // Outward normal = rotate tangent vector 90° clockwise (CCW path
      // convention has outward to the right).
      final tx = tangent.vector.dx;
      final ty = tangent.vector.dy;
      final nx = ty;
      final ny = -tx;

      final wave = math.sin(t * 2 * math.pi * waveCount + phase) * waveAmplitude;
      final px = pos.dx + nx * wave;
      final py = pos.dy + ny * wave;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant WigglyButtonPainter old) {
    return old.phase != phase ||
        old.fillColor != fillColor ||
        old.strokeColor != strokeColor ||
        old.borderRadius != borderRadius ||
        old.waveAmplitude != waveAmplitude ||
        old.waveCount != waveCount ||
        old.strokeWidth != strokeWidth;
  }
}
