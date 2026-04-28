// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_defaults.dart';
import 'internal/wiggly_dots_canvas.dart';
import 'wiggly_loaders_theme.dart';

/// A compact row of wiggly dots for inline loading and status states.
///
/// **Determinate** — fills dots progressively from left to right:
/// ```dart
/// WigglyDotsLoader(progress: 0.6)
/// ```
///
/// **Indeterminate** — a highlighted cluster travels across the row:
/// ```dart
/// WigglyDotsLoader.indeterminate()
/// ```
class WigglyDotsLoader extends StatefulWidget {
  WigglyDotsLoader({
    super.key,
    required double progress,
    this.dotCount = 3,
    this.dotSize = 8.0,
    this.spacing = 6.0,
    this.wiggleAmplitude = 2.5,
    this.progressColor = WigglyDefaults.dotsProgressColor,
    this.trackColor = WigglyDefaults.dotsTrackColor,
    this.duration = const Duration(milliseconds: 900),
    this.willAnimate = true,
    this.semanticsLabel,
    this.semanticsValue,
  })  : _progress = progress,
        _indeterminate = false,
        assert(
          progress >= 0.0 && progress <= 1.0,
          'progress must be between 0.0 and 1.0',
        ),
        assert(dotCount > 0, 'dotCount must be greater than 0'),
        assert(dotSize > 0.0, 'dotSize must be greater than 0'),
        assert(spacing >= 0.0, 'spacing must be at least 0'),
        assert(
          wiggleAmplitude >= 0.0,
          'wiggleAmplitude must be at least 0',
        );

  WigglyDotsLoader.indeterminate({
    Key? key,
    int dotCount = 3,
    double dotSize = 8.0,
    double spacing = 6.0,
    double wiggleAmplitude = 2.5,
    Color progressColor = WigglyDefaults.dotsProgressColor,
    Color trackColor = WigglyDefaults.dotsTrackColor,
    Duration duration = const Duration(milliseconds: 900),
    bool willAnimate = true,
    String? semanticsLabel,
    String? semanticsValue,
  }) : this._(
          key: key,
          progress: 0.0,
          indeterminate: true,
          dotCount: dotCount,
          dotSize: dotSize,
          spacing: spacing,
          wiggleAmplitude: wiggleAmplitude,
          progressColor: progressColor,
          trackColor: trackColor,
          duration: duration,
          willAnimate: willAnimate,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
        );

  WigglyDotsLoader._({
    super.key,
    required double progress,
    required bool indeterminate,
    required this.dotCount,
    required this.dotSize,
    required this.spacing,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.trackColor,
    required this.duration,
    required this.willAnimate,
    required this.semanticsLabel,
    required this.semanticsValue,
  })  : _progress = progress,
        _indeterminate = indeterminate;

  final double _progress;
  final bool _indeterminate;

  final int dotCount;
  final double dotSize;
  final double spacing;
  final double wiggleAmplitude;
  final Color progressColor;
  final Color trackColor;
  final Duration duration;
  final bool willAnimate;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  State<WigglyDotsLoader> createState() => _WigglyDotsLoaderState();
}

class _WigglyDotsLoaderState extends State<WigglyDotsLoader>
    with TickerProviderStateMixin {
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.65;

  late final AnimationController _phaseController;
  late final AnimationController _travelController;
  late final Animation<double> _phaseAnim;
  late Animation<double> _travelAnim;
  late final AnimationController _entryController;
  late final Animation<double> _entryAnim;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    _phaseController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.duration),
    )..repeat();

    _travelController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.duration),
    );

    _phaseAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _phaseController, curve: Curves.linear),
    );
    _travelAnim = _buildTravelAnimation();

    _entryController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(const Duration(milliseconds: 420)),
    )
      ..addListener(_handleEntryTick)
      ..addStatusListener(_handleEntryStatus);

    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    if (widget.willAnimate) {
      _entryController.forward(from: 0.0);
    } else {
      _entryController.value = 1.0;
    }

    if (widget._indeterminate && !widget.willAnimate) {
      _travelController.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final nextReduceMotion = mediaQuery?.disableAnimations ?? _reduceMotion;

    if (_reduceMotion != nextReduceMotion) {
      _reduceMotion = nextReduceMotion;
      _applyEffectiveDurations();
    }
  }

  @override
  void didUpdateWidget(covariant WigglyDotsLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.willAnimate != widget.willAnimate) {
      if (widget.willAnimate) {
        _travelController
          ..stop()
          ..reset();
        _entryController.forward(from: 0.0);
      } else {
        _entryController.value = 1.0;
        if (widget._indeterminate) {
          _travelController.repeat();
        }
      }
    }

    if (oldWidget.duration != widget.duration ||
        oldWidget.dotCount != widget.dotCount) {
      _applyEffectiveDurations();
      _travelAnim = _buildTravelAnimation();
    }

    if (oldWidget._indeterminate != widget._indeterminate) {
      if (widget._indeterminate) {
        _travelAnim = _buildTravelAnimation();

        if (widget.willAnimate && !_entryController.isCompleted) {
          _travelController
            ..stop()
            ..reset();
        } else {
          _travelController.repeat();
        }
      } else {
        _travelController
          ..stop()
          ..reset();
      }
    }
  }

  void _handleEntryTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget._indeterminate) {
      _travelController.repeat();
    }
  }

  Animation<double> _buildTravelAnimation() {
    return Tween<double>(
      begin: -1.0,
      end: widget.dotCount.toDouble(),
    ).animate(
      CurvedAnimation(parent: _travelController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _travelController.dispose();
    _entryController
      ..removeListener(_handleEntryTick)
      ..removeStatusListener(_handleEntryStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = WigglyLoadersTheme.maybeOf(context);
    final resolvedProgressColor =
        widget.progressColor == WigglyDefaults.dotsProgressColor
            ? (theme?.dotsProgressColor ?? widget.progressColor)
            : widget.progressColor;
    final resolvedTrackColor =
        widget.trackColor == WigglyDefaults.dotsTrackColor
            ? (theme?.dotsTrackColor ?? widget.trackColor)
            : widget.trackColor;
    final resolvedWiggleAmplitude = _effectiveAmplitude(widget.wiggleAmplitude);
    final entryValue = widget.willAnimate ? _entryAnim.value : 1.0;
    final showIndeterminateIntro = widget._indeterminate &&
        widget.willAnimate &&
        !_entryController.isCompleted;
    final semanticsLabel = widget.semanticsLabel ??
        (widget._indeterminate ? 'Loading' : 'Loading progress');
    final semanticsValue = widget.semanticsValue ??
        (widget._indeterminate
            ? null
            : '${(widget._progress * 100).round()} percent');

    return Semantics(
      container: true,
      label: semanticsLabel,
      value: semanticsValue,
      child: WigglyDotsCanvas(
        progress:
            showIndeterminateIntro ? entryValue : widget._progress * entryValue,
        indeterminate: widget._indeterminate && !showIndeterminateIntro,
        phase: _phaseAnim,
        travel: _travelAnim,
        dotCount: widget.dotCount,
        dotSize: widget.dotSize,
        spacing: widget.spacing,
        wiggleAmplitude: resolvedWiggleAmplitude,
        progressColor: resolvedProgressColor,
        trackColor: resolvedTrackColor,
      ),
    );
  }

  Duration _effectiveDuration(Duration duration) {
    if (!_reduceMotion) {
      return duration;
    }

    return Duration(
      microseconds:
          (duration.inMicroseconds * _reducedMotionDurationScale).round(),
    );
  }

  double _effectiveAmplitude(double amplitude) {
    if (!_reduceMotion) {
      return amplitude;
    }

    return amplitude * _reducedMotionAmplitudeScale;
  }

  void _applyEffectiveDurations() {
    final duration = _effectiveDuration(widget.duration);

    _phaseController.duration = duration;
    if (_phaseController.isAnimating) {
      _phaseController.repeat();
    }

    _travelController.duration = duration;
    if (_travelController.isAnimating) {
      _travelController.repeat();
    }

    _entryController.duration =
        _effectiveDuration(const Duration(milliseconds: 420));
  }
}
