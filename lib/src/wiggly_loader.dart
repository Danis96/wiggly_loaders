import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_defaults.dart';
import 'internal/wiggly_arc_canvas.dart';
import 'wiggly_loaders_theme.dart';

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
    this.progressColor = WigglyDefaults.loaderProgressColor,
    this.trackColor = WigglyDefaults.loaderTrackColor,
    this.wiggleDuration = const Duration(milliseconds: 1200),
    this.rotateDuration = const Duration(milliseconds: 1600),
    this.arcSpan = 0.7,
    this.willAnimate = true,
    this.child,
    this.semanticsLabel,
    this.semanticsValue,
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
    Color progressColor = WigglyDefaults.loaderProgressColor,
    Color trackColor = WigglyDefaults.loaderTrackColor,
    Duration wiggleDuration = const Duration(milliseconds: 1200),
    Duration rotateDuration = const Duration(milliseconds: 1600),
    double arcSpan = 0.7,
    bool willAnimate = true,
    Widget? child,
    String? semanticsLabel,
    String? semanticsValue,
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
          willAnimate: willAnimate,
          child: child,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
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
    required this.willAnimate,
    required this.child,
    required this.semanticsLabel,
    required this.semanticsValue,
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

  /// Whether to play an intro animation when the widget is shown.
  final bool willAnimate;

  /// Optional widget to display in the center of the loader.
  final Widget? child;

  /// Optional semantic label for assistive technologies.
  final String? semanticsLabel;

  /// Optional semantic value for assistive technologies.
  final String? semanticsValue;

  @override
  State<WigglyLoader> createState() => _WigglyLoaderState();
}

class _WigglyLoaderState extends State<WigglyLoader>
    with TickerProviderStateMixin {
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.65;

  late final AnimationController _wiggleController;
  late final AnimationController _rotateController;
  late final Animation<double> _phaseAnim;
  late final Animation<double> _rotateAnim;
  late final AnimationController _entryController;
  late final Animation<double> _entryAnim;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    _wiggleController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.wiggleDuration),
    )..repeat();

    _rotateController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.rotateDuration),
    );

    _phaseAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.linear),
    );

    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(const Duration(milliseconds: 520)),
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
      _rotateController.repeat();
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

  void _handleEntryTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget._indeterminate) {
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WigglyLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.willAnimate != widget.willAnimate) {
      if (widget.willAnimate) {
        _rotateController
          ..stop()
          ..reset();
        _entryController.forward(from: 0.0);
      } else {
        _entryController.value = 1.0;
        if (widget._indeterminate) {
          _rotateController.repeat();
        }
      }
    }

    if (oldWidget.wiggleDuration != widget.wiggleDuration ||
        oldWidget.rotateDuration != widget.rotateDuration) {
      _applyEffectiveDurations();
    }

    if (oldWidget._indeterminate != widget._indeterminate) {
      if (widget._indeterminate) {
        if (widget.willAnimate && !_entryController.isCompleted) {
          _rotateController
            ..stop()
            ..reset();
        } else {
          _rotateController.repeat();
        }
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
        widget.progressColor == WigglyDefaults.loaderProgressColor
            ? (theme?.loaderProgressColor ?? widget.progressColor)
            : widget.progressColor;
    final resolvedTrackColor = widget.trackColor == WigglyDefaults.loaderTrackColor
        ? (theme?.loaderTrackColor ?? widget.trackColor)
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
      child: WigglyArcCanvas(
        size: widget.size,
        progress:
            showIndeterminateIntro ? entryValue : widget._progress * entryValue,
        indeterminate: widget._indeterminate && !showIndeterminateIntro,
        phase: _phaseAnim,
        rotation: _rotateAnim,
        strokeWidth: widget.strokeWidth,
        wiggleCount: widget.wiggleCount,
        wiggleAmplitude: resolvedWiggleAmplitude,
        progressColor: resolvedProgressColor,
        trackColor: resolvedTrackColor,
        arcSpan: widget.arcSpan,
        child: widget.child,
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
    _wiggleController.duration = _effectiveDuration(widget.wiggleDuration);
    if (_wiggleController.isAnimating) {
      _wiggleController.repeat();
    }

    _rotateController.duration = _effectiveDuration(widget.rotateDuration);
    if (_rotateController.isAnimating) {
      _rotateController.repeat();
    }

    _entryController.duration =
        _effectiveDuration(const Duration(milliseconds: 520));
  }
}
