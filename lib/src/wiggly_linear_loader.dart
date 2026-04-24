import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_linear_canvas.dart';

/// A wiggly/wavy horizontal linear loading indicator.
///
/// **Determinate** — shows a fixed progress bar (0.0–1.0):
/// ```dart
/// WigglyLinearLoader(progress: 0.6)
/// ```
///
/// **Indeterminate** — a segment slides across continuously:
/// ```dart
/// WigglyLinearLoader.indeterminate()
/// ```
class WigglyLinearLoader extends StatefulWidget {
  /// Determinate mode: a wiggly bar filling [progress] fraction of the width.
  const WigglyLinearLoader({
    super.key,
    required double progress,
    this.height = 6.0,
    this.wiggleCount = 8,
    this.wiggleAmplitude = 2.5,
    this.progressColor = const Color(0xFF3B82F6),
    this.trackColor = const Color(0xFFE5E7EB),
    this.wiggleDuration = const Duration(milliseconds: 1000),
    this.slideDuration = const Duration(milliseconds: 1400),
    this.segmentFraction = 0.45,
    this.borderRadius = 99.0,
  })  : _progress = progress,
        _indeterminate = false,
        assert(
          progress >= 0.0 && progress <= 1.0,
          'progress must be between 0.0 and 1.0',
        );

  /// Indeterminate mode: a wiggly segment that slides across continuously.
  const WigglyLinearLoader.indeterminate({
    Key? key,
    double height = 6.0,
    int wiggleCount = 8,
    double wiggleAmplitude = 2.5,
    Color progressColor = const Color(0xFF3B82F6),
    Color trackColor = const Color(0xFFE5E7EB),
    Duration wiggleDuration = const Duration(milliseconds: 1000),
    Duration slideDuration = const Duration(milliseconds: 1400),
    double segmentFraction = 0.45,
    double borderRadius = 99.0,
  }) : this._(
          key: key,
          progress: 0.0,
          indeterminate: true,
          height: height,
          wiggleCount: wiggleCount,
          wiggleAmplitude: wiggleAmplitude,
          progressColor: progressColor,
          trackColor: trackColor,
          wiggleDuration: wiggleDuration,
          slideDuration: slideDuration,
          segmentFraction: segmentFraction,
          borderRadius: borderRadius,
        );

  const WigglyLinearLoader._({
    super.key,
    required double progress,
    required bool indeterminate,
    required this.height,
    required this.wiggleCount,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.trackColor,
    required this.wiggleDuration,
    required this.slideDuration,
    required this.segmentFraction,
    required this.borderRadius,
  })  : _progress = progress,
        _indeterminate = indeterminate;

  final double _progress;
  final bool _indeterminate;

  /// Height of the track in logical pixels.
  final double height;

  /// Number of wiggle cycles across the full bar width.
  final int wiggleCount;

  /// Vertical amplitude of the wiggle in logical pixels.
  final double wiggleAmplitude;

  /// Color of the progress/segment stroke.
  final Color progressColor;

  /// Color of the background track.
  final Color trackColor;

  /// Duration of one full wiggle phase cycle.
  final Duration wiggleDuration;

  /// Duration of one full slide cycle in indeterminate mode.
  final Duration slideDuration;

  /// Fraction of the bar width the indeterminate segment spans (0.0–1.0).
  final double segmentFraction;

  /// Border radius of the track background. Defaults to fully rounded (pill).
  final double borderRadius;

  @override
  State<WigglyLinearLoader> createState() => _WigglyLinearLoaderState();
}

class _WigglyLinearLoaderState extends State<WigglyLinearLoader>
    with TickerProviderStateMixin {
  late final AnimationController _wiggleController;
  late final AnimationController _slideController;
  late final Animation<double> _phaseAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _wiggleController = AnimationController(
      vsync: this,
      duration: widget.wiggleDuration,
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: widget.slideDuration,
    );

    _phaseAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.linear),
    );

    _slideAnim = _buildSlideAnimation();

    if (widget._indeterminate) {
      _slideController.repeat();
    }
  }

  Animation<double> _buildSlideAnimation() {
    return Tween<double>(
      begin: -widget.segmentFraction,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant WigglyLinearLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wiggleDuration != widget.wiggleDuration) {
      _wiggleController.duration = widget.wiggleDuration;
      if (_wiggleController.isAnimating) {
        _wiggleController.repeat();
      }
    }

    if (oldWidget.slideDuration != widget.slideDuration) {
      _slideController.duration = widget.slideDuration;
      if (widget._indeterminate) {
        _slideController.repeat();
      }
    }

    if (oldWidget._indeterminate != widget._indeterminate ||
        oldWidget.segmentFraction != widget.segmentFraction) {
      _slideAnim = _buildSlideAnimation();

      if (widget._indeterminate) {
        _slideController.repeat();
      } else {
        _slideController
          ..stop()
          ..reset();
      }
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WigglyLinearCanvas(
      height: widget.height,
      wiggleAmplitude: widget.wiggleAmplitude,
      progress: widget._progress,
      indeterminate: widget._indeterminate,
      phase: _phaseAnim,
      slideOffset: _slideAnim,
      wiggleCount: widget.wiggleCount,
      progressColor: widget.progressColor,
      trackColor: widget.trackColor,
      segmentFraction: widget.segmentFraction,
      borderRadius: widget.borderRadius,
    );
  }
}
