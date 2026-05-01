import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_defaults.dart';
import 'internal/wiggly_refresh_badge.dart';
import 'wiggly_loaders_theme.dart';

/// A pull-to-refresh indicator that shows a wiggly arc while pulling
/// and spins indeterminately while the refresh future is in progress.
///
/// Drop-in replacement for Flutter's [RefreshIndicator]. Wrap any
/// scrollable widget (ListView, GridView, CustomScrollView, etc.).
///
/// Basic usage:
/// ```dart
/// WigglyRefreshIndicator(
///   onRefresh: () async {
///     await fetchData();
///   },
///   child: ListView(...),
/// )
/// ```
///
/// Custom styling:
/// ```dart
/// WigglyRefreshIndicator(
///   onRefresh: _handleRefresh,
///   progressColor: Colors.teal,
///   trackColor: Colors.teal.shade50,
///   size: 56,
///   displacement: 60,
///   wiggleCount: 12,
///   wiggleAmplitude: 4.0,
///   child: ListView(...),
/// )
/// ```
class WigglyRefreshIndicator extends StatefulWidget {
  const WigglyRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 50.0,
    this.triggerDistance = 80.0,
    this.maxDragDistance = 120.0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.size = 52.0,
    this.strokeWidth = 4.0,
    this.wiggleCount = 14,
    this.wiggleAmplitude = 3.5,
    this.progressColor = WigglyDefaults.refreshProgressColor,
    this.progressEndColor,
    this.trackColor = WigglyDefaults.refreshTrackColor,
    this.backgroundColor = WigglyDefaults.refreshBackgroundColor,
    this.wiggleDuration = const Duration(milliseconds: 1200),
    this.rotateDuration = const Duration(milliseconds: 1500),
    this.arcSpan = 0.7,
    this.elevation = 2.0,
    this.semanticsLabel = 'Pull to refresh',
  })  : assert(displacement >= 0.0, 'displacement must be at least 0'),
        assert(
          triggerDistance > 0.0,
          'triggerDistance must be greater than 0',
        ),
        assert(
          maxDragDistance >= triggerDistance,
          'maxDragDistance must be at least triggerDistance',
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
        ),
        assert(elevation >= 0.0, 'elevation must be at least 0');

  /// Called when the user completes a pull-to-refresh gesture.
  /// The indicator keeps spinning until the returned [Future] resolves.
  final Future<void> Function() onRefresh;

  /// The scrollable widget to wrap.
  final Widget child;

  /// Distance from the top edge where the badge rests while refreshing.
  final double displacement;

  /// Drag distance that triggers refresh on release.
  final double triggerDistance;

  /// Maximum overscroll drag distance tracked for progress.
  final double maxDragDistance;

  /// Predicate to filter which scroll notifications are handled.
  final ScrollNotificationPredicate notificationPredicate;

  /// Diameter of the indicator circle in logical pixels.
  final double size;

  /// Stroke width of the arc and track.
  final double strokeWidth;

  /// Number of wiggle cycles around the arc.
  final int wiggleCount;

  /// Amplitude of the wiggle in logical pixels.
  final double wiggleAmplitude;

  /// Start color of the wiggly arc.
  final Color progressColor;

  /// Optional end color for gradient interpolation across the arc.
  ///
  /// Defaults to [progressColor] for a flat stroke.
  final Color? progressEndColor;

  /// Color of the background track ring.
  final Color trackColor;

  /// Background color of the circular badge card.
  final Color backgroundColor;

  /// Duration of one wiggle phase cycle.
  final Duration wiggleDuration;

  /// Duration of one full spin during the refreshing state.
  final Duration rotateDuration;

  /// Fraction of the circle the spinning arc covers (0.0–1.0).
  final double arcSpan;

  /// Elevation of the badge card shadow.
  final double elevation;

  /// Semantic label for assistive technologies.
  final String semanticsLabel;

  @override
  State<WigglyRefreshIndicator> createState() => _WigglyRefreshIndicatorState();
}

class _WigglyRefreshIndicatorState extends State<WigglyRefreshIndicator>
    with TickerProviderStateMixin {
  static const double _defaultSize = 52.0;
  static const double _defaultStrokeWidth = 4.0;
  static const Duration _defaultWiggleDuration = Duration(milliseconds: 1200);
  static const Duration _defaultRotateDuration = Duration(milliseconds: 1500);
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.65;

  late final AnimationController _wiggleController;
  late final Animation<double> _phaseAnim;
  late final AnimationController _rotateController;
  late final Animation<double> _rotateAnim;
  WigglyLoadersThemeData? _theme;
  bool _reduceMotion = false;

  double _dragProgress = 0.0;
  bool _refreshing = false;
  bool _dragging = false;
  double _dragOffset = 0.0;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final nextReduceMotion = mediaQuery?.disableAnimations ?? _reduceMotion;
    final nextTheme = WigglyLoadersTheme.maybeOf(context);
    final themeChanged = _theme != nextTheme;
    _theme = nextTheme;

    if (_reduceMotion != nextReduceMotion) {
      _reduceMotion = nextReduceMotion;
      _applyEffectiveDurations();
    }

    if (themeChanged) {
      _applyEffectiveDurations();
    }
  }

  @override
  void didUpdateWidget(covariant WigglyRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wiggleDuration != widget.wiggleDuration ||
        oldWidget.rotateDuration != widget.rotateDuration) {
      _applyEffectiveDurations();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _startRefresh() async {
    if (_refreshing) {
      return;
    }

    setState(() => _refreshing = true);
    _rotateController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _rotateController
          ..stop()
          ..reset();

        setState(() {
          _refreshing = false;
          _dragProgress = 0.0;
          _dragOffset = 0.0;
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }

    if (_refreshing) return false;

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      final delta = -notification.overscroll;
      final newOffset =
          (_dragOffset + delta).clamp(0.0, widget.maxDragDistance);
      setState(() {
        _dragging = true;
        _dragOffset = newOffset;
        _dragProgress = (_dragOffset / widget.triggerDistance).clamp(0.0, 1.0);
      });
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.metrics.extentBefore == 0) {
      final delta = -(notification.scrollDelta ?? 0.0);
      if (delta > 0) {
        final newOffset =
            (_dragOffset + delta).clamp(0.0, widget.maxDragDistance);
        setState(() {
          _dragging = true;
          _dragOffset = newOffset;
          _dragProgress =
              (_dragOffset / widget.triggerDistance).clamp(0.0, 1.0);
        });
      }
    }

    if (notification is ScrollEndNotification) {
      if (_dragOffset >= widget.triggerDistance) {
        setState(() {
          _dragOffset = widget.displacement;
          _dragProgress = 1.0;
          _dragging = false;
        });
        _startRefresh();
      } else {
        setState(() {
          _dragging = false;
          _dragOffset = 0.0;
          _dragProgress = 0.0;
        });
      }
    }

    return false;
  }

  bool get _visible => _refreshing || _dragging || _dragProgress > 0;

  @override
  Widget build(BuildContext context) {
    final resolvedProgressColor =
        widget.progressColor == WigglyDefaults.refreshProgressColor
            ? (_theme?.refreshProgressColor ??
                _theme?.progressColor ??
                widget.progressColor)
            : widget.progressColor;
    final resolvedProgressEndColor = widget.progressEndColor;
    final resolvedTrackColor = widget.trackColor ==
            WigglyDefaults.refreshTrackColor
        ? (_theme?.refreshTrackColor ?? _theme?.trackColor ?? widget.trackColor)
        : widget.trackColor;
    final resolvedBackgroundColor =
        widget.backgroundColor == WigglyDefaults.refreshBackgroundColor
            ? (_theme?.refreshBackgroundColor ??
                _theme?.backgroundColor ??
                widget.backgroundColor)
            : widget.backgroundColor;
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
    final resolvedWiggleAmplitude = _effectiveAmplitude(widget.wiggleAmplitude);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        if (_visible)
          Positioned(
            top: _refreshing ? widget.displacement : _dragOffset - widget.size,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                container: true,
                label: widget.semanticsLabel,
                value: _refreshing
                    ? 'Refreshing'
                    : '${(_dragProgress * 100).round()} percent',
                child: WigglyRefreshBadge(
                  key: const ValueKey('wiggly_refresh_badge'),
                  progress: _refreshing ? 1.0 : _dragProgress,
                  indeterminate: _refreshing,
                  phase: _phaseAnim,
                  rotation: _rotateAnim,
                  size: resolvedSize,
                  strokeWidth: resolvedStrokeWidth,
                  wiggleCount: widget.wiggleCount,
                  wiggleAmplitude: resolvedWiggleAmplitude,
                  progressColor: resolvedProgressColor,
                  progressEndColor: resolvedProgressEndColor,
                  trackColor: resolvedTrackColor,
                  backgroundColor: resolvedBackgroundColor,
                  arcSpan: widget.arcSpan,
                  elevation: widget.elevation,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Duration _effectiveDuration(Duration duration) {
    final themedDuration = _resolveDuration(
      value: duration,
      defaultValue: duration == widget.wiggleDuration
          ? _defaultWiggleDuration
          : _defaultRotateDuration,
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
