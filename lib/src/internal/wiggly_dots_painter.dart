import 'dart:math' as math;

import 'package:flutter/material.dart';

class WigglyDotsPainter extends CustomPainter {
  WigglyDotsPainter({
    required this.progress,
    required this.indeterminate,
    required this.phase,
    required this.travel,
    required this.dotCount,
    required this.dotSize,
    required this.spacing,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.progressEndColor,
    required this.trackColor,
  });

  final double progress;
  final bool indeterminate;
  final double phase;
  final double travel;
  final int dotCount;
  final double dotSize;
  final double spacing;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color? progressEndColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final baseRadius = dotSize / 2;
    final centerY = size.height / 2;
    final progressPosition = progress * dotCount;

    for (var index = 0; index < dotCount; index++) {
      final centerX = baseRadius + index * (dotSize + spacing);
      final waveT = dotCount == 1 ? 0.0 : index / (dotCount - 1);
      final y =
          centerY + math.sin(waveT * 2 * math.pi + phase) * wiggleAmplitude;
      final emphasis = indeterminate
          ? _indeterminateEmphasis(index.toDouble())
          : (progressPosition - index).clamp(0.0, 1.0);
      final radius = baseRadius * (0.82 + emphasis * 0.18);
      final activeColor = _progressColorForIndex(index);
      final color = Color.lerp(trackColor, activeColor, emphasis)!;

      canvas.drawCircle(
        Offset(centerX, y),
        radius,
        Paint()..color = color,
      );
    }
  }

  double _indeterminateEmphasis(double dotIndex) {
    final distance = (dotIndex - travel).abs();
    if (distance >= 1.6) {
      return 0.0;
    }

    final raw = 1.0 - (distance / 1.6);
    return Curves.easeOut.transform(raw.clamp(0.0, 1.0));
  }

  Color _progressColorForIndex(int index) {
    final endColor = progressEndColor ?? progressColor;
    if (endColor == progressColor || dotCount <= 1) {
      return progressColor;
    }

    return Color.lerp(progressColor, endColor, index / (dotCount - 1))!;
  }

  @override
  bool shouldRepaint(covariant WigglyDotsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.indeterminate != indeterminate ||
        oldDelegate.phase != phase ||
        oldDelegate.travel != travel ||
        oldDelegate.dotCount != dotCount ||
        oldDelegate.dotSize != dotSize ||
        oldDelegate.spacing != spacing ||
        oldDelegate.wiggleAmplitude != wiggleAmplitude ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progressEndColor != progressEndColor ||
        oldDelegate.trackColor != trackColor;
  }
}
