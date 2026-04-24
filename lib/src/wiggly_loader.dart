import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_arc_canvas.dart';

/// A customizable wiggly/wavy circular loading indicator.
///
/// **Determinate** — shows a fixed progress arc (0.0–1.0):
/// ```dart
/// WigglyLoader(progress: 0.76)
/// ```
///
/// **Indeterminate** — arc sweeps continuously, used when progress is unknown:
/// ```dart
/// WigglyLoader.indeterminate()
/// ```
class WigglyLoader extends StatefulWidget {
  /// Determinate mode: shows a fixed arc representing [progress] (0.0–1.0).
  const WigglyLoader({
    super.key,
    required double progress,
    this.size = 72.0,
    this.strokeWidth = 4.5,
    this.wiggleCount = 14,
    this.wiggleAmplitude = 3.5,
    this.progressColor = const Color(0xFF3B82F6),
    this.trackColor = const Color(0xFFE5E7EB),
    this.wiggleDuration = const Duration(milliseconds: 1200),
    this.rotateDuration = const Duration(milliseconds: 1600),
    this.arcSpan = 0.7,
    this.child,
  })  : _progress = progress,
        _indeterminate = false,
        assert(
          progress >= 0.0 && progress <= 1.0,
          'progress must be between 0.0 and 1.0',
        );

  /// Indeterminate mode: arc rotates continuously with no fixed progress value.
  const WigglyLoader.indeterminate({
    Key? key,
    double size = 72.0,
    double strokeWidth = 4.5,
    int wiggleCount = 14,
    double wiggleAmplitude = 3.5,
    Color progressColor = const Color(0xFF3B82F6),
    Color trackColor = const Color(0xFFE5E7EB),
    Duration wiggleDuration = const Duration(milliseconds: 1200),
    Duration rotateDuration = const Duration(milliseconds: 1600),
    double arcSpan = 0.7,
    Widget? child,
  }) : this._(
          key: key,
          progress: 0.0,
          indeterminate: true,
          size: size,
          strokeWidth: strokeWidth,
          wiggleCount: wiggleCount,
          wiggleAmplitude: wiggleAmplitude,
          progressColor: progressColor,
          trackColor: trackColor,
          wiggleDuration: wiggleDuration,
          rotateDuration: rotateDuration,
          arcSpan: arcSpan,
          child: child,
        );

  const WigglyLoader._({
    super.key,
    required double progress,
    required bool indeterminate,
    required this.size,
    required this.strokeWidth,
    required this.wiggleCount,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.trackColor,
    required this.wiggleDuration,
    required this.rotateDuration,
    required this.arcSpan,
    required this.child,
  })  : _progress = progress,
        _indeterminate = indeterminate;

  final double _progress;
  final bool _indeterminate;

  /// Diameter of the loader in logical pixels.
  final double size;

  /// Width of both the track and the progress stroke.
  final double strokeWidth;

  /// Number of full wiggle cycles along the arc.
  final int wiggleCount;

  /// Amplitude of the wiggle in logical pixels.
  final double wiggleAmplitude;

  /// Color of the animated progress arc.
  final Color progressColor;

  /// Color of the background track arc.
  final Color trackColor;

  /// Duration of one full wiggle phase animation cycle.
  final Duration wiggleDuration;

  /// Duration of one full rotation in indeterminate mode.
  final Duration rotateDuration;

  /// Fraction of the full circle the indeterminate arc spans (0.0–1.0).
  /// Ignored in determinate mode.
  final double arcSpan;

  /// Optional widget to display in the center of the loader.
  final Widget? child;

  @override
  State<WigglyLoader> createState() => _WigglyLoaderState();
}

class _WigglyLoaderState extends State<WigglyLoader>
    with TickerProviderStateMixin {
  late final AnimationController _wiggleController;
  late final AnimationController _rotateController;
  late final Animation<double> _phaseAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();

    _wiggleController = AnimationController(
      vsync: this,
      duration: widget.wiggleDuration,
    )..repeat();

    _rotateController = AnimationController(
      vsync: this,
      duration: widget.rotateDuration,
    );

    _phaseAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.linear),
    );

    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    if (widget._indeterminate) {
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WigglyLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wiggleDuration != widget.wiggleDuration) {
      _wiggleController.duration = widget.wiggleDuration;
      if (_wiggleController.isAnimating) {
        _wiggleController.repeat();
      }
    }

    if (oldWidget.rotateDuration != widget.rotateDuration) {
      _rotateController.duration = widget.rotateDuration;
      if (widget._indeterminate) {
        _rotateController.repeat();
      }
    }

    if (oldWidget._indeterminate != widget._indeterminate) {
      if (widget._indeterminate) {
        _rotateController.repeat();
      } else {
        _rotateController
          ..stop()
          ..reset();
      }
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WigglyArcCanvas(
      size: widget.size,
      progress: widget._progress,
      indeterminate: widget._indeterminate,
      phase: _phaseAnim,
      rotation: _rotateAnim,
      strokeWidth: widget.strokeWidth,
      wiggleCount: widget.wiggleCount,
      wiggleAmplitude: widget.wiggleAmplitude,
      progressColor: widget.progressColor,
      trackColor: widget.trackColor,
      arcSpan: widget.arcSpan,
      child: widget.child,
    );
  }
}
