import 'dart:math' as math;

import 'package:flutter/material.dart';

class WigglyArcPainter extends CustomPainter {
  WigglyArcPainter({
    required this.progress,
    required this.indeterminate,
    required this.phase,
    required this.rotation,
    required this.strokeWidth,
    required this.wiggleCount,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.trackColor,
    required this.arcSpan,
    this.trackStrokeCap = StrokeCap.round,
  });

  final double progress;
  final bool indeterminate;
  final double phase;
  final double rotation;
  final double strokeWidth;
  final int wiggleCount;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color trackColor;
  final double arcSpan;
  final StrokeCap trackStrokeCap;

  static const double _startAngle = -math.pi / 2;
  static const int _segments = 300;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth - wiggleAmplitude;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = trackStrokeCap,
    );

    if (indeterminate) {
      _buildAndDrawPath(
        canvas: canvas,
        center: center,
        radius: radius,
        arcFraction: arcSpan,
        angleOffset: _startAngle + rotation,
      );
    } else if (progress > 0.0) {
      _buildAndDrawPath(
        canvas: canvas,
        center: center,
        radius: radius,
        arcFraction: progress,
        angleOffset: _startAngle,
      );
    }
  }

  void _buildAndDrawPath({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double arcFraction,
    required double angleOffset,
  }) {
    final sweepAngle = 2 * math.pi * arcFraction;
    final segmentCount = (_segments * arcFraction).ceil().clamp(2, _segments);
    final path = Path();
    var started = false;

    for (var i = 0; i <= segmentCount; i++) {
      final t = i / _segments;
      final angle = angleOffset + t * 2 * math.pi;
      if (angle > angleOffset + sweepAngle + 1e-6) {
        break;
      }

      final wiggleOffset =
          math.sin(t * wiggleCount * 2 * math.pi + phase) * wiggleAmplitude;
      final currentRadius = radius + wiggleOffset;
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant WigglyArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.indeterminate != indeterminate ||
        oldDelegate.phase != phase ||
        oldDelegate.rotation != rotation ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.wiggleCount != wiggleCount ||
        oldDelegate.wiggleAmplitude != wiggleAmplitude ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcSpan != arcSpan ||
        oldDelegate.trackStrokeCap != trackStrokeCap;
  }
}
