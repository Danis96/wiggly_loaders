import 'package:flutter/material.dart';

import 'wiggly_linear_painter.dart';

class WigglyLinearCanvas extends StatelessWidget {
  const WigglyLinearCanvas({
    super.key,
    required this.height,
    required this.wiggleAmplitude,
    required this.progress,
    required this.indeterminate,
    required this.phase,
    required this.slideOffset,
    required this.wiggleCount,
    required this.progressColor,
    required this.progressEndColor,
    required this.trackColor,
    required this.segmentFraction,
    required this.borderRadius,
    required this.debug,
  });

  final double height;
  final double wiggleAmplitude;
  final double progress;
  final bool indeterminate;
  final Animation<double> phase;
  final Animation<double> slideOffset;
  final int wiggleCount;
  final Color progressColor;
  final Color? progressEndColor;
  final Color trackColor;
  final double segmentFraction;
  final double borderRadius;
  final bool debug;

  @override
  Widget build(BuildContext context) {
    final totalHeight = height + wiggleAmplitude * 2;

    return SizedBox(
      height: totalHeight,
      child: AnimatedBuilder(
        animation: Listenable.merge([phase, slideOffset]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: WigglyLinearPainter(
              progress: progress,
              indeterminate: indeterminate,
              phase: phase.value,
              slideOffset: slideOffset.value,
              height: height,
              wiggleCount: wiggleCount,
              wiggleAmplitude: wiggleAmplitude,
              progressColor: progressColor,
              progressEndColor: progressEndColor,
              trackColor: trackColor,
              segmentFraction: segmentFraction,
              borderRadius: borderRadius,
              debug: debug,
            ),
          );
        },
      ),
    );
  }
}
