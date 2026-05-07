import 'package:flutter/material.dart';

import 'wiggly_dots_painter.dart';

class WigglyDotsCanvas extends StatelessWidget {
  const WigglyDotsCanvas({
    super.key,
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
    required this.debug,
  });

  final double progress;
  final bool indeterminate;
  final Animation<double> phase;
  final Animation<double> travel;
  final int dotCount;
  final double dotSize;
  final double spacing;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color? progressEndColor;
  final Color trackColor;
  final bool debug;

  @override
  Widget build(BuildContext context) {
    final width = dotCount * dotSize + (dotCount - 1) * spacing;
    final height = dotSize + wiggleAmplitude * 2;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: Listenable.merge([phase, travel]),
        builder: (context, _) {
          return CustomPaint(
            painter: WigglyDotsPainter(
              progress: progress,
              indeterminate: indeterminate,
              phase: phase.value,
              travel: travel.value,
              dotCount: dotCount,
              dotSize: dotSize,
              spacing: spacing,
              wiggleAmplitude: wiggleAmplitude,
              progressColor: progressColor,
              progressEndColor: progressEndColor,
              trackColor: trackColor,
              debug: debug,
            ),
          );
        },
      ),
    );
  }
}
