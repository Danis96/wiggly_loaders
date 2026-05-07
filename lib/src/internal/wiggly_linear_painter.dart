import 'dart:math' as math;

import 'package:flutter/material.dart';

class WigglyLinearPainter extends CustomPainter {
  WigglyLinearPainter({
    required this.progress,
    required this.indeterminate,
    required this.phase,
    required this.slideOffset,
    required this.height,
    required this.wiggleCount,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.progressEndColor,
    required this.trackColor,
    required this.segmentFraction,
    required this.borderRadius,
    required this.debug,
  });

  final double progress;
  final bool indeterminate;
  final double phase;
  final double slideOffset;
  final double height;
  final int wiggleCount;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color? progressEndColor;
  final Color trackColor;
  final double segmentFraction;
  final double borderRadius;
  final bool debug;

  static const int _segments = 300;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final effectiveRadius = math.min(borderRadius, height / 2);

    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        cy - height / 2,
        size.width,
        cy + height / 2,
        Radius.circular(effectiveRadius),
      ),
      Paint()..color = trackColor,
    );

    if (debug) {
      canvas.drawLine(
        Offset(0, cy),
        Offset(size.width, cy),
        Paint()
          ..color = const Color(0x88EF4444)
          ..strokeWidth = 1.0,
      );
    }

    if (indeterminate) {
      _drawIndeterminateSegment(canvas, size, cy);
    } else if (progress > 0.0) {
      _drawDeterminateBar(canvas, size, cy);
    }
  }

  void _drawDeterminateBar(Canvas canvas, Size size, double cy) {
    final endX = size.width * progress;
    _clipAndDraw(
      canvas,
      size,
      cy,
      startX: 0,
      endX: endX,
      _buildWigglyPath(
        startX: 0,
        endX: endX,
        cy: cy,
        totalWidth: size.width,
      ),
    );
  }

  void _drawIndeterminateSegment(Canvas canvas, Size size, double cy) {
    final segmentWidth = size.width * segmentFraction;
    final startX = size.width * slideOffset;
    final endX = startX + segmentWidth;
    _clipAndDraw(
      canvas,
      size,
      cy,
      startX: startX,
      endX: endX,
      _buildWigglyPath(
        startX: startX,
        endX: endX,
        cy: cy,
        totalWidth: size.width,
      ),
    );
  }

  Path _buildWigglyPath({
    required double startX,
    required double endX,
    required double cy,
    required double totalWidth,
  }) {
    final path = Path();
    final segmentWidth = endX - startX;
    if (segmentWidth <= 0) {
      return path;
    }

    var started = false;
    for (var i = 0; i <= _segments; i++) {
      final t = i / _segments;
      final x = startX + t * segmentWidth;
      final waveT = (x / totalWidth) * wiggleCount * 2 * math.pi;
      final y = cy + math.sin(waveT + phase) * wiggleAmplitude;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  void _clipAndDraw(
    Canvas canvas,
    Size size,
    double cy,
    Path path, {
    required double startX,
    required double endX,
  }) {
    final effectiveRadius = math.min(borderRadius, height / 2);
    canvas.save();
    canvas.clipRRect(
      RRect.fromLTRBR(
        0,
        cy - height / 2,
        size.width,
        cy + height / 2,
        Radius.circular(effectiveRadius),
      ),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = height
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shader = _buildProgressShader(
      size: size,
      startX: startX,
      endX: endX,
      cy: cy,
    );

    if (shader != null) {
      paint.shader = shader;
    } else {
      paint.color = progressColor;
    }

    canvas.drawPath(path, paint);

    if (debug) {
      final guidePaint = Paint()
        ..color = const Color(0xCCEF4444)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(startX, cy - height),
        Offset(startX, cy + height),
        guidePaint,
      );
      canvas.drawLine(
        Offset(endX, cy - height),
        Offset(endX, cy + height),
        guidePaint,
      );

      for (final metric in path.computeMetrics()) {
        for (var i = 0; i <= wiggleCount * 2; i++) {
          final tangent = metric.getTangentForOffset(
            metric.length * (i / (wiggleCount * 2)),
          );
          if (tangent == null) {
            continue;
          }
          canvas.drawCircle(
            tangent.position,
            1.75,
            Paint()..color = const Color(0xCCEF4444),
          );
        }
      }
    }

    canvas.restore();
  }

  Shader? _buildProgressShader({
    required Size size,
    required double startX,
    required double endX,
    required double cy,
  }) {
    final endColor = progressEndColor ?? progressColor;
    if (endColor == progressColor || endX <= startX) {
      return null;
    }

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [progressColor, endColor],
    ).createShader(
      Rect.fromLTRB(startX, cy - height / 2, endX, cy + height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant WigglyLinearPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.indeterminate != indeterminate ||
        oldDelegate.phase != phase ||
        oldDelegate.slideOffset != slideOffset ||
        oldDelegate.height != height ||
        oldDelegate.wiggleCount != wiggleCount ||
        oldDelegate.wiggleAmplitude != wiggleAmplitude ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progressEndColor != progressEndColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.segmentFraction != segmentFraction ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.debug != debug;
  }
}
