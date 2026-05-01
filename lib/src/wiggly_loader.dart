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
    this.onComplete,
    this.completeDuration = const Duration(milliseconds: 450),
  })  : _progress = progress,
        _indeterminate = false,
        assert(
          progress >= 0.0 && progress <= 1.0,
          'progress must be between 0.0 and 1.0',
        ),
        assert(size > 0.0, 'size must be greater than 0'),
        assert(strokeWidth > 0.0, 'strokeWidth must be greater than 0'),
        assert(wiggleCount > 0, 'wiggleCount must be greater than 0'),
        assert(
          wiggleAmplitude >= 0.0,
          'wiggleAmplitude must be at least 0',
        ),
        assert(
          arcSpan >= 0.0 && arcSpan <= 1.0,
          'arcSpan must be between 0.0 and 1.0',
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
          onComplete: null,
          completeDuration: const Duration(milliseconds: 450),
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
    required this.onComplete,
    required this.completeDuration,
  })  : _progress = progress,
        _indeterminate = indeterminate,
        assert(size > 0.0, 'size must be greater than 0'),
        assert(strokeWidth > 0.0, 'strokeWidth must be greater than 0'),
        assert(wiggleCount > 0, 'wiggleCount must be greater than 0'),
        assert(
          wiggleAmplitude >= 0.0,
          'wiggleAmplitude must be at least 0',
        ),
        assert(
          arcSpan >= 0.0 && arcSpan <= 1.0,
          'arcSpan must be between 0.0 and 1.0',
        );

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

  /// Called once after the burst animation finishes when [progress] reaches `1.0`.
  final VoidCallback? onComplete;

  /// Duration of the burst animation played when [progress] reaches `1.0`.
  final Duration completeDuration;

  @override
  State<WigglyLoader> createState() => _WigglyLoaderState();
}

class _WigglyLoaderState extends State<WigglyLoader>
    with TickerProviderStateMixin {
  static const double _defaultSize = 72.0;
  static const double _defaultStrokeWidth = 4.5;
  static const Duration _defaultWiggleDuration = Duration(milliseconds: 1200);
  static const Duration _defaultRotateDuration = Duration(milliseconds: 1600);
  static const Duration _defaultEntryDuration = Duration(milliseconds: 520);
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.65;

  late final AnimationController _wiggleController;
  late final AnimationController _rotateController;
  late final Animation<double> _phaseAnim;
  late final Animation<double> _rotateAnim;
  late final AnimationController _entryController;
  late Animation<double> _entryAnim;
  late final AnimationController _burstController;
  double _burstMultiplier = 1.0;
  WigglyLoadersThemeData? _theme;
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
      duration: _effectiveDuration(_defaultEntryDuration),
    )
      ..addListener(_handleEntryTick)
      ..addStatusListener(_handleEntryStatus);

    _entryAnim = _buildEntryAnimation();

    if (widget.willAnimate) {
      _entryController.forward(from: 0.0);
    } else {
      _entryController.value = 1.0;
    }

    if (widget._indeterminate && !widget.willAnimate) {
      _rotateController.repeat();
    }

    _burstController = AnimationController(
      vsync: this,
      duration: widget.completeDuration,
    )
      ..addListener(_handleBurstTick)
      ..addStatusListener(_handleBurstStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final nextReduceMotion = mediaQuery?.disableAnimations ?? _reduceMotion;
    final nextTheme = WigglyLoadersTheme.maybeOf(context);
    final themeChanged = _theme != nextTheme;
    final easeChanged = _theme?.ease != nextTheme?.ease;
    _theme = nextTheme;

    if (_reduceMotion != nextReduceMotion) {
      _reduceMotion = nextReduceMotion;
      _applyEffectiveDurations();
    }

    if (themeChanged) {
      _applyEffectiveDurations();
    }

    if (easeChanged) {
      _entryAnim = _buildEntryAnimation();
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

  void _handleBurstTick() {
    if (mounted) {
      setState(() {
        _burstMultiplier =
            1.0 + 1.5 * math.sin(_burstController.value * math.pi);
      });
    }
  }

  void _handleBurstStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _burstMultiplier = 1.0);
      widget.onComplete?.call();
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

    if (oldWidget.completeDuration != widget.completeDuration) {
      _burstController.duration = widget.completeDuration;
    }

    if (!widget._indeterminate &&
        oldWidget._progress < 1.0 &&
        widget._progress >= 1.0) {
      if (_reduceMotion) {
        widget.onComplete?.call();
      } else {
        _burstController.forward(from: 0.0);
      }
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
    _burstController
      ..removeListener(_handleBurstTick)
      ..removeStatusListener(_handleBurstStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedProgressColor =
        widget.progressColor == WigglyDefaults.loaderProgressColor
            ? (_theme?.loaderProgressColor ??
                _theme?.progressColor ??
                widget.progressColor)
            : widget.progressColor;
    final resolvedTrackColor = widget.trackColor ==
            WigglyDefaults.loaderTrackColor
        ? (_theme?.loaderTrackColor ?? _theme?.trackColor ?? widget.trackColor)
        : widget.trackColor;
    final resolvedSize = _resolveScaledValue(
      value: widget.size,
      defaultValue: _defaultSize,
      scale: _theme?.sizeScale,
    );
    final resolvedStrokeWidth = _resolveScaledValue(
      value: widget.strokeWidth,
      defaultValue: _defaultStrokeWidth,
      scale: _theme?.strokeWidthScale,
    );
    final resolvedWiggleAmplitude =
        _effectiveAmplitude(widget.wiggleAmplitude) * _burstMultiplier;
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
        size: resolvedSize,
        progress:
            showIndeterminateIntro ? entryValue : widget._progress * entryValue,
        indeterminate: widget._indeterminate && !showIndeterminateIntro,
        phase: _phaseAnim,
        rotation: _rotateAnim,
        strokeWidth: resolvedStrokeWidth,
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
    final themedDuration = _resolveDuration(
      value: duration,
      defaultValue: _defaultDurationFor(duration),
    );

    if (!_reduceMotion) {
      return themedDuration;
    }

    return Duration(
      microseconds:
          (themedDuration.inMicroseconds * _reducedMotionDurationScale).round(),
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

    _entryController.duration = _effectiveDuration(_defaultEntryDuration);
  }

  Animation<double> _buildEntryAnimation() {
    return CurvedAnimation(
      parent: _entryController,
      curve: _theme?.ease ?? Curves.easeOutCubic,
    );
  }

  Duration _resolveDuration({
    required Duration value,
    required Duration defaultValue,
  }) {
    if (value != defaultValue) {
      return value;
    }

    final speedFactor = _theme?.speedFactor;
    if (speedFactor == null || speedFactor == 1.0) {
      return value;
    }

    return Duration(
      microseconds: (value.inMicroseconds / speedFactor).round(),
    );
  }

  Duration _defaultDurationFor(Duration duration) {
    if (duration == widget.wiggleDuration) {
      return _defaultWiggleDuration;
    }
    if (duration == widget.rotateDuration) {
      return _defaultRotateDuration;
    }
    return _defaultEntryDuration;
  }

  double _resolveScaledValue({
    required double value,
    required double defaultValue,
    required double? scale,
  }) {
    if (value != defaultValue || scale == null || scale == 1.0) {
      return value;
    }

    return value * scale;
  }
}
