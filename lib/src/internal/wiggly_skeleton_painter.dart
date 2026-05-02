import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints a skeleton block with a wiggly highlight wave traveling across it.
///
/// Differentiator: the highlight is a sinusoidal "tube" that snakes across
/// the surface — the wave actually travels rather than a flat shimmer pulse.
class WigglySkeletonPainter extends CustomPainter {
  WigglySkeletonPainter({
    required this.phase,
    required this.travel,
    required this.baseColor,
    required this.highlightColor,
    required this.borderRadius,
    required this.waveAmplitude,
    required this.waveLength,
    required this.bandWidth,
  });

  final double phase;
  final double travel;
  final Color baseColor;
  final Color highlightColor;
  final double borderRadius;
  final double waveAmplitude;
  final double waveLength;
  final double bandWidth;

  static const int _segments = 90;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(borderRadius, math.min(size.width, size.height) / 2);
    final rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      Radius.circular(radius),
    );

    canvas.drawRRect(rrect, Paint()..color = baseColor);

    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    canvas.save();
    canvas.clipRRect(rrect);

    // Travel sweeps from -bandWidth to size.width + bandWidth so the wave
    // enters and exits the shape smoothly.
    final sweep = size.width + bandWidth * 2;
    final centerX = -bandWidth + travel * sweep;
    final cy = size.height / 2;
    final amp = math.min(waveAmplitude, size.height / 2 - 1).clamp(0.0, double.infinity);

    // Build the wiggly center path of the band.
    final path = Path();
    for (var i = 0; i <= _segments; i++) {
      final t = i / _segments;
      final x = centerX - bandWidth + t * (bandWidth * 2);
      final waveT = (x / waveLength) * 2 * math.pi;
      final y = cy + math.sin(waveT + phase) * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Soft highlight stroke (wide, low alpha) layered on a thinner core.
    final softStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.height * 0.9
      ..color = highlightColor.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.25);

    final coreStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.height * 0.45
      ..color = highlightColor.withValues(alpha: 0.85);

    canvas.drawPath(path, softStroke);
    canvas.drawPath(path, coreStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WigglySkeletonPainter old) {
    return old.phase != phase ||
        old.travel != travel ||
        old.baseColor != baseColor ||
        old.highlightColor != highlightColor ||
        old.borderRadius != borderRadius ||
        old.waveAmplitude != waveAmplitude ||
        old.waveLength != waveLength ||
        old.bandWidth != bandWidth;
  }
}
