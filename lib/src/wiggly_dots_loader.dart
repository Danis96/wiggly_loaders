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
  const WigglyDotsLoader({
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
    this.onComplete,
    this.completeDuration = const Duration(milliseconds: 450),
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

  const WigglyDotsLoader.indeterminate({
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
          onComplete: null,
          completeDuration: const Duration(milliseconds: 450),
        );

  const WigglyDotsLoader._({
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
    required this.onComplete,
    required this.completeDuration,
  })  : _progress = progress,
        _indeterminate = indeterminate,
        assert(dotCount > 0, 'dotCount must be greater than 0'),
        assert(dotSize > 0.0, 'dotSize must be greater than 0'),
        assert(spacing >= 0.0, 'spacing must be at least 0'),
        assert(
          wiggleAmplitude >= 0.0,
          'wiggleAmplitude must be at least 0',
        );

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

  /// Called once after the burst animation finishes when [progress] reaches `1.0`.
  final VoidCallback? onComplete;

  /// Duration of the burst animation played when [progress] reaches `1.0`.
  final Duration completeDuration;

  @override
  State<WigglyDotsLoader> createState() => _WigglyDotsLoaderState();
}

class _WigglyDotsLoaderState extends State<WigglyDotsLoader>
    with TickerProviderStateMixin {
  static const double _defaultDotSize = 8.0;
  static const double _defaultSpacing = 6.0;
  static const Duration _defaultDuration = Duration(milliseconds: 900);
  static const Duration _defaultEntryDuration = Duration(milliseconds: 420);
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.65;

  late final AnimationController _phaseController;
  late final AnimationController _travelController;
  late final Animation<double> _phaseAnim;
  late Animation<double> _travelAnim;
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
      _travelController.repeat();
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
      _travelAnim = _buildTravelAnimation();
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

  Animation<double> _buildTravelAnimation() {
    return Tween<double>(
      begin: -1.0,
      end: widget.dotCount.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _travelController,
        curve: _theme?.ease ?? Curves.easeInOut,
      ),
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
    _burstController
      ..removeListener(_handleBurstTick)
      ..removeStatusListener(_handleBurstStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedProgressColor =
        widget.progressColor == WigglyDefaults.dotsProgressColor
            ? (_theme?.dotsProgressColor ??
                _theme?.progressColor ??
                widget.progressColor)
            : widget.progressColor;
    final resolvedTrackColor = widget.trackColor ==
            WigglyDefaults.dotsTrackColor
        ? (_theme?.dotsTrackColor ?? _theme?.trackColor ?? widget.trackColor)
        : widget.trackColor;
    final resolvedDotSize = _resolveScaledValue(
      value: widget.dotSize,
      defaultValue: _defaultDotSize,
      scale: _theme?.sizeScale,
    );
    final resolvedSpacing = _resolveScaledValue(
      value: widget.spacing,
      defaultValue: _defaultSpacing,
      scale: _theme?.sizeScale,
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
      child: WigglyDotsCanvas(
        progress:
            showIndeterminateIntro ? entryValue : widget._progress * entryValue,
        indeterminate: widget._indeterminate && !showIndeterminateIntro,
        phase: _phaseAnim,
        travel: _travelAnim,
        dotCount: widget.dotCount,
        dotSize: resolvedDotSize,
        spacing: resolvedSpacing,
        wiggleAmplitude: resolvedWiggleAmplitude,
        progressColor: resolvedProgressColor,
        trackColor: resolvedTrackColor,
      ),
    );
  }

  Duration _effectiveDuration(Duration duration) {
    final themedDuration = _resolveDuration(
      value: duration,
      defaultValue: duration == widget.duration
          ? _defaultDuration
          : _defaultEntryDuration,
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
    final duration = _effectiveDuration(widget.duration);

    _phaseController.duration = duration;
    if (_phaseController.isAnimating) {
      _phaseController.repeat();
    }

    _travelController.duration = duration;
    if (_travelController.isAnimating) {
      _travelController.repeat();
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
