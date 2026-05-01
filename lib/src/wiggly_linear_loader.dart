import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_defaults.dart';
import 'internal/wiggly_linear_canvas.dart';
import 'wiggly_loaders_theme.dart';

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
    this.progressColor = WigglyDefaults.linearProgressColor,
    this.progressEndColor,
    this.trackColor = WigglyDefaults.linearTrackColor,
    this.wiggleDuration = const Duration(milliseconds: 1000),
    this.slideDuration = const Duration(milliseconds: 1400),
    this.segmentFraction = 0.45,
    this.borderRadius = 99.0,
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
        assert(height > 0.0, 'height must be greater than 0'),
        assert(wiggleCount > 0, 'wiggleCount must be greater than 0'),
        assert(
          wiggleAmplitude >= 0.0,
          'wiggleAmplitude must be at least 0',
        ),
        assert(
          segmentFraction > 0.0 && segmentFraction <= 1.0,
          'segmentFraction must be between 0.0 and 1.0',
        ),
        assert(borderRadius >= 0.0, 'borderRadius must be at least 0');

  /// Indeterminate mode: a wiggly segment that slides across continuously.
  const WigglyLinearLoader.indeterminate({
    Key? key,
    double height = 6.0,
    int wiggleCount = 8,
    double wiggleAmplitude = 2.5,
    Color progressColor = WigglyDefaults.linearProgressColor,
    Color? progressEndColor,
    Color trackColor = WigglyDefaults.linearTrackColor,
    Duration wiggleDuration = const Duration(milliseconds: 1000),
    Duration slideDuration = const Duration(milliseconds: 1400),
    double segmentFraction = 0.45,
    double borderRadius = 99.0,
    bool willAnimate = true,
    String? semanticsLabel,
    String? semanticsValue,
  }) : this._(
          key: key,
          progress: 0.0,
          indeterminate: true,
          height: height,
          wiggleCount: wiggleCount,
          wiggleAmplitude: wiggleAmplitude,
          progressColor: progressColor,
          progressEndColor: progressEndColor,
          trackColor: trackColor,
          wiggleDuration: wiggleDuration,
          slideDuration: slideDuration,
          segmentFraction: segmentFraction,
          borderRadius: borderRadius,
          willAnimate: willAnimate,
          semanticsLabel: semanticsLabel,
          semanticsValue: semanticsValue,
          onComplete: null,
          completeDuration: const Duration(milliseconds: 450),
        );

  const WigglyLinearLoader._({
    super.key,
    required double progress,
    required bool indeterminate,
    required this.height,
    required this.wiggleCount,
    required this.wiggleAmplitude,
    required this.progressColor,
    required this.progressEndColor,
    required this.trackColor,
    required this.wiggleDuration,
    required this.slideDuration,
    required this.segmentFraction,
    required this.borderRadius,
    required this.willAnimate,
    required this.semanticsLabel,
    required this.semanticsValue,
    required this.onComplete,
    required this.completeDuration,
  })  : _progress = progress,
        _indeterminate = indeterminate,
        assert(height > 0.0, 'height must be greater than 0'),
        assert(wiggleCount > 0, 'wiggleCount must be greater than 0'),
        assert(
          wiggleAmplitude >= 0.0,
          'wiggleAmplitude must be at least 0',
        ),
        assert(
          segmentFraction > 0.0 && segmentFraction <= 1.0,
          'segmentFraction must be between 0.0 and 1.0',
        ),
        assert(borderRadius >= 0.0, 'borderRadius must be at least 0');

  final double _progress;
  final bool _indeterminate;

  /// Height of the track in logical pixels.
  final double height;

  /// Number of wiggle cycles across the full bar width.
  final int wiggleCount;

  /// Vertical amplitude of the wiggle in logical pixels.
  final double wiggleAmplitude;

  /// Start color of the progress/segment stroke.
  final Color progressColor;

  /// Optional end color for gradient interpolation across the filled segment.
  ///
  /// Defaults to [progressColor] for a flat stroke.
  final Color? progressEndColor;

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

  /// Whether to play an intro animation when the widget is shown.
  final bool willAnimate;

  /// Optional semantic label for assistive technologies.
  final String? semanticsLabel;

  /// Optional semantic value for assistive technologies.
  final String? semanticsValue;

  /// Called once after the burst animation finishes when [progress] reaches `1.0`.
  final VoidCallback? onComplete;

  /// Duration of the burst animation played when [progress] reaches `1.0`.
  final Duration completeDuration;

  @override
  State<WigglyLinearLoader> createState() => _WigglyLinearLoaderState();
}

class _WigglyLinearLoaderState extends State<WigglyLinearLoader>
    with TickerProviderStateMixin {
  static const double _defaultHeight = 6.0;
  static const Duration _defaultWiggleDuration = Duration(milliseconds: 1000);
  static const Duration _defaultSlideDuration = Duration(milliseconds: 1400);
  static const Duration _defaultEntryDuration = Duration(milliseconds: 520);
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.65;

  late final AnimationController _wiggleController;
  late final AnimationController _slideController;
  late final Animation<double> _phaseAnim;
  late Animation<double> _slideAnim;
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

    _slideController = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.slideDuration),
    );

    _phaseAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.linear),
    );

    _slideAnim = _buildSlideAnimation();

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
      _slideController.repeat();
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
      _slideAnim = _buildSlideAnimation();
    }
  }

  Animation<double> _buildSlideAnimation() {
    return Tween<double>(
      begin: -widget.segmentFraction,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: _theme?.ease ?? Curves.easeInOut,
      ),
    );
  }

  void _handleEntryTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleEntryStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget._indeterminate) {
      _slideController.repeat();
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
  void didUpdateWidget(covariant WigglyLinearLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.willAnimate != widget.willAnimate) {
      if (widget.willAnimate) {
        _slideController
          ..stop()
          ..reset();
        _entryController.forward(from: 0.0);
      } else {
        _entryController.value = 1.0;
        if (widget._indeterminate) {
          _slideController.repeat();
        }
      }
    }

    if (oldWidget.wiggleDuration != widget.wiggleDuration ||
        oldWidget.slideDuration != widget.slideDuration) {
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

    if (oldWidget._indeterminate != widget._indeterminate ||
        oldWidget.segmentFraction != widget.segmentFraction) {
      _slideAnim = _buildSlideAnimation();

      if (widget._indeterminate) {
        if (widget.willAnimate && !_entryController.isCompleted) {
          _slideController
            ..stop()
            ..reset();
        } else {
          _slideController.repeat();
        }
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
        widget.progressColor == WigglyDefaults.linearProgressColor
            ? (_theme?.linearProgressColor ??
                _theme?.progressColor ??
                widget.progressColor)
            : widget.progressColor;
    final resolvedProgressEndColor = widget.progressEndColor;
    final resolvedTrackColor = widget.trackColor ==
            WigglyDefaults.linearTrackColor
        ? (_theme?.linearTrackColor ?? _theme?.trackColor ?? widget.trackColor)
        : widget.trackColor;
    final resolvedHeight = _resolveScaledValue(
      value: widget.height,
      defaultValue: _defaultHeight,
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
      child: WigglyLinearCanvas(
        height: resolvedHeight,
        wiggleAmplitude: resolvedWiggleAmplitude,
        progress:
            showIndeterminateIntro ? entryValue : widget._progress * entryValue,
        indeterminate: widget._indeterminate && !showIndeterminateIntro,
        phase: _phaseAnim,
        slideOffset: _slideAnim,
        wiggleCount: widget.wiggleCount,
        progressColor: resolvedProgressColor,
        progressEndColor: resolvedProgressEndColor,
        trackColor: resolvedTrackColor,
        segmentFraction: widget.segmentFraction,
        borderRadius: widget.borderRadius,
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

    _slideController.duration = _effectiveDuration(widget.slideDuration);
    if (_slideController.isAnimating) {
      _slideController.repeat();
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
    if (duration == widget.slideDuration) {
      return _defaultSlideDuration;
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
