import 'package:flutter/material.dart';

import 'wiggly_arc_canvas.dart';

class WigglyRefreshBadge extends StatelessWidget {
  const WigglyRefreshBadge({
    super.key,
    required this.progress,
    required this.indeterminate,
    required this.phase,
    required this.rotation,
    required this.size,
    required this.strokeWidth,
    required this.wiggleCount,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.trackColor,
    required this.backgroundColor,
    required this.arcSpan,
    required this.elevation,
  });

  final double progress;
  final bool indeterminate;
  final Animation<double> phase;
  final Animation<double> rotation;
  final double size;
  final double strokeWidth;
  final int wiggleCount;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color trackColor;
  final Color backgroundColor;
  final double arcSpan;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      shape: const CircleBorder(),
      color: backgroundColor,
      child: WigglyArcCanvas(
        size: size,
        progress: progress,
        indeterminate: indeterminate,
        phase: phase,
        rotation: rotation,
        strokeWidth: strokeWidth,
        wiggleCount: wiggleCount,
        wiggleAmplitude: wiggleAmplitude,
        progressColor: progressColor,
        trackColor: trackColor,
        arcSpan: arcSpan,
        trackStrokeCap: StrokeCap.butt,
      ),
    );
  }
}
