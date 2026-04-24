import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_refresh_badge.dart';

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
    this.size = 52.0,
    this.strokeWidth = 4.0,
    this.wiggleCount = 14,
    this.wiggleAmplitude = 3.5,
    this.progressColor = const Color(0xFF3B89F6),
    this.trackColor = const Color(0xFFE5E7EB),
    this.backgroundColor = Colors.white,
    this.wiggleDuration = const Duration(milliseconds: 1200),
    this.rotateDuration = const Duration(milliseconds: 1500),
    this.arcSpan = 0.7,
    this.elevation = 2.0,
  });

  /// Called when the user completes a pull-to-refresh gesture.
  /// The indicator keeps spinning until the returned [Future] resolves.
  final Future<void> Function() onRefresh;

  /// The scrollable widget to wrap.
  final Widget child;

  /// Distance from the top edge where the badge rests while refreshing.
  final double displacement;

  /// Diameter of the indicator circle in logical pixels.
  final double size;

  /// Stroke width of the arc and track.
  final double strokeWidth;

  /// Number of wiggle cycles around the arc.
  final int wiggleCount;

  /// Amplitude of the wiggle in logical pixels.
  final double wiggleAmplitude;

  /// Color of the wiggly arc.
  final Color progressColor;

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

  @override
  State<WigglyRefreshIndicator> createState() => _WigglyRefreshIndicatorState();
}

class _WigglyRefreshIndicatorState extends State<WigglyRefreshIndicator>
    with TickerProviderStateMixin {
  static const double _triggerDistance = 80.0;
  static const double _maxDragDistance = 120.0;

  late final AnimationController _wiggleController;
  late final Animation<double> _phaseAnim;
  late final AnimationController _rotateController;
  late final Animation<double> _rotateAnim;

  double _dragProgress = 0.0;
  bool _refreshing = false;
  bool _dragging = false;
  double _dragOffset = 0.0;

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
  }

  @override
  void didUpdateWidget(covariant WigglyRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wiggleDuration != widget.wiggleDuration) {
      _wiggleController.duration = widget.wiggleDuration;
      if (_wiggleController.isAnimating) {
        _wiggleController.repeat();
      }
    }

    if (oldWidget.rotateDuration != widget.rotateDuration) {
      _rotateController.duration = widget.rotateDuration;
      if (_refreshing) {
        _rotateController.repeat();
      }
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
    if (_refreshing) return false;

    if (notification is OverscrollNotification &&
        notification.overscroll < 0) {
      final delta = -notification.overscroll;
      final newOffset = (_dragOffset + delta).clamp(0.0, _maxDragDistance);
      setState(() {
        _dragging = true;
        _dragOffset = newOffset;
        _dragProgress = (_dragOffset / _triggerDistance).clamp(0.0, 1.0);
      });
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.metrics.extentBefore == 0) {
      final delta = -(notification.scrollDelta ?? 0.0);
      if (delta > 0) {
        final newOffset = (_dragOffset + delta).clamp(0.0, _maxDragDistance);
        setState(() {
          _dragging = true;
          _dragOffset = newOffset;
          _dragProgress = (_dragOffset / _triggerDistance).clamp(0.0, 1.0);
        });
      }
    }

    if (notification is ScrollEndNotification) {
      if (_dragOffset >= _triggerDistance) {
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
              child: WigglyRefreshBadge(
                key: const ValueKey('wiggly_refresh_badge'),
                progress: _refreshing ? 1.0 : _dragProgress,
                indeterminate: _refreshing,
                phase: _phaseAnim,
                rotation: _rotateAnim,
                size: widget.size,
                strokeWidth: widget.strokeWidth,
                wiggleCount: widget.wiggleCount,
                wiggleAmplitude: widget.wiggleAmplitude,
                progressColor: widget.progressColor,
                trackColor: widget.trackColor,
                backgroundColor: widget.backgroundColor,
                arcSpan: widget.arcSpan,
                elevation: widget.elevation,
              ),
            ),
          ),
      ],
    );
  }
}
