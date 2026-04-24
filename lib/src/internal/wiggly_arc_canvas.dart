import 'package:flutter/material.dart';

import 'wiggly_arc_painter.dart';

class WigglyArcCanvas extends StatelessWidget {
  const WigglyArcCanvas({
    super.key,
    required this.size,
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
    this.child,
    this.trackStrokeCap = StrokeCap.round,
  });

  final double size;
  final double progress;
  final bool indeterminate;
  final Animation<double> phase;
  final Animation<double> rotation;
  final double strokeWidth;
  final int wiggleCount;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color trackColor;
  final double arcSpan;
  final Widget? child;
  final StrokeCap trackStrokeCap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([phase, rotation]),
        builder: (context, _) {
          return CustomPaint(
            painter: WigglyArcPainter(
              progress: progress,
              indeterminate: indeterminate,
              phase: phase.value,
              rotation: rotation.value,
              strokeWidth: strokeWidth,
              wiggleCount: wiggleCount,
              wiggleAmplitude: wiggleAmplitude,
              progressColor: progressColor,
              trackColor: trackColor,
              arcSpan: arcSpan,
              trackStrokeCap: trackStrokeCap,
            ),
            child: child != null ? Center(child: child) : null,
          );
        },
      ),
    );
  }
}
