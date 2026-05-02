import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_defaults.dart';
import 'internal/wiggly_skeleton_painter.dart';
import 'wiggly_loaders_theme.dart';

/// A shimmering skeleton placeholder where the highlight is a wiggly wave
/// that travels horizontally across the shape — instead of the flat gradient
/// shimmer most packages use.
///
/// **Single block:**
/// ```dart
/// WigglySkeletonLoader(width: 200, height: 16)
/// ```
///
/// **Text lines preset:**
/// ```dart
/// WigglySkeletonLoader.text(lines: 3)
/// ```
///
/// **Card preset (avatar + lines):**
/// ```dart
/// WigglySkeletonLoader.card()
/// ```
class WigglySkeletonLoader extends StatefulWidget {
  /// A single rounded skeleton block.
  const WigglySkeletonLoader({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius = 8.0,
    this.baseColor = WigglyDefaults.skeletonBaseColor,
    this.highlightColor = WigglyDefaults.skeletonHighlightColor,
    this.duration = const Duration(milliseconds: 1400),
    this.waveAmplitude = 4.0,
    this.waveLength = 28.0,
    this.bandWidth = 56.0,
    this.willAnimate = true,
    this.semanticsLabel,
  })  : _variant = _SkeletonVariant.block,
        _lines = 0,
        _lineHeight = 0,
        _lineSpacing = 0,
        _lastLineFraction = 1.0,
        _avatarSize = 0,
        assert(height > 0, 'height must be > 0'),
        assert(borderRadius >= 0, 'borderRadius must be >= 0'),
        assert(waveAmplitude >= 0, 'waveAmplitude must be >= 0'),
        assert(waveLength > 0, 'waveLength must be > 0'),
        assert(bandWidth > 0, 'bandWidth must be > 0');

  /// Multi-line text placeholder. The last line is shortened to feel natural.
  const WigglySkeletonLoader.text({
    Key? key,
    int lines = 3,
    double lineHeight = 14.0,
    double lineSpacing = 10.0,
    double lastLineFraction = 0.6,
    double borderRadius = 6.0,
    Color baseColor = WigglyDefaults.skeletonBaseColor,
    Color highlightColor = WigglyDefaults.skeletonHighlightColor,
    Duration duration = const Duration(milliseconds: 1400),
    double waveAmplitude = 3.0,
    double waveLength = 26.0,
    double bandWidth = 56.0,
    bool willAnimate = true,
    String? semanticsLabel,
  }) : this._(
          key: key,
          variant: _SkeletonVariant.text,
          width: null,
          height: lineHeight,
          borderRadius: borderRadius,
          baseColor: baseColor,
          highlightColor: highlightColor,
          duration: duration,
          waveAmplitude: waveAmplitude,
          waveLength: waveLength,
          bandWidth: bandWidth,
          willAnimate: willAnimate,
          semanticsLabel: semanticsLabel,
          lines: lines,
          lineHeight: lineHeight,
          lineSpacing: lineSpacing,
          lastLineFraction: lastLineFraction,
          avatarSize: 0,
        );

  /// Card preset — circular avatar on the left, three text lines on the right.
  const WigglySkeletonLoader.card({
    Key? key,
    double avatarSize = 44.0,
    int lines = 3,
    double lineHeight = 12.0,
    double lineSpacing = 9.0,
    double lastLineFraction = 0.55,
    double borderRadius = 6.0,
    Color baseColor = WigglyDefaults.skeletonBaseColor,
    Color highlightColor = WigglyDefaults.skeletonHighlightColor,
    Duration duration = const Duration(milliseconds: 1400),
    double waveAmplitude = 3.0,
    double waveLength = 26.0,
    double bandWidth = 56.0,
    bool willAnimate = true,
    String? semanticsLabel,
  }) : this._(
          key: key,
          variant: _SkeletonVariant.card,
          width: null,
          height: lineHeight,
          borderRadius: borderRadius,
          baseColor: baseColor,
          highlightColor: highlightColor,
          duration: duration,
          waveAmplitude: waveAmplitude,
          waveLength: waveLength,
          bandWidth: bandWidth,
          willAnimate: willAnimate,
          semanticsLabel: semanticsLabel,
          lines: lines,
          lineHeight: lineHeight,
          lineSpacing: lineSpacing,
          lastLineFraction: lastLineFraction,
          avatarSize: avatarSize,
        );

  const WigglySkeletonLoader._({
    super.key,
    required _SkeletonVariant variant,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
    required this.waveAmplitude,
    required this.waveLength,
    required this.bandWidth,
    required this.willAnimate,
    required this.semanticsLabel,
    required int lines,
    required double lineHeight,
    required double lineSpacing,
    required double lastLineFraction,
    required double avatarSize,
  })  : _variant = variant,
        _lines = lines,
        _lineHeight = lineHeight,
        _lineSpacing = lineSpacing,
        _lastLineFraction = lastLineFraction,
        _avatarSize = avatarSize,
        assert(height > 0, 'height must be > 0'),
        assert(borderRadius >= 0, 'borderRadius must be >= 0'),
        assert(lines > 0, 'lines must be > 0'),
        assert(
          lastLineFraction > 0 && lastLineFraction <= 1.0,
          'lastLineFraction must be in (0, 1]',
        );

  final double? width;
  final double height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final double waveAmplitude;
  final double waveLength;
  final double bandWidth;
  final bool willAnimate;
  final String? semanticsLabel;

  final _SkeletonVariant _variant;
  final int _lines;
  final double _lineHeight;
  final double _lineSpacing;
  final double _lastLineFraction;
  final double _avatarSize;

  @override
  State<WigglySkeletonLoader> createState() => _WigglySkeletonLoaderState();
}

enum _SkeletonVariant { block, text, card }

class _WigglySkeletonLoaderState extends State<WigglySkeletonLoader>
    with TickerProviderStateMixin {
  static const Duration _defaultDuration = Duration(milliseconds: 1400);
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.5;

  late final AnimationController _controller;
  WigglyLoadersThemeData? _theme;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    _controller = AnimationController(
      vsync: this,
      duration: _effectiveDuration(widget.duration),
    );

    if (widget.willAnimate) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final nextReduceMotion = mediaQuery?.disableAnimations ?? _reduceMotion;
    final nextTheme = WigglyLoadersTheme.maybeOf(context);
    final themeChanged = _theme != nextTheme;
    _theme = nextTheme;

    if (_reduceMotion != nextReduceMotion || themeChanged) {
      _reduceMotion = nextReduceMotion;
      _controller.duration = _effectiveDuration(widget.duration);
      if (widget.willAnimate) {
        _controller.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(covariant WigglySkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = _effectiveDuration(widget.duration);
    }
    if (oldWidget.willAnimate != widget.willAnimate) {
      if (widget.willAnimate) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _effectiveDuration(Duration duration) {
    final speedFactor = _theme?.speedFactor;
    var resolved = duration;
    if (duration == _defaultDuration && speedFactor != null && speedFactor != 1.0) {
      resolved = Duration(
        microseconds: (duration.inMicroseconds / speedFactor).round(),
      );
    }
    if (_reduceMotion) {
      resolved = Duration(
        microseconds: (resolved.inMicroseconds * _reducedMotionDurationScale).round(),
      );
    }
    return resolved;
  }

  double _effectiveAmplitude(double amplitude) {
    return _reduceMotion ? amplitude * _reducedMotionAmplitudeScale : amplitude;
  }

  Color get _resolvedBase =>
      widget.baseColor == WigglyDefaults.skeletonBaseColor
          ? (_theme?.skeletonBaseColor ?? widget.baseColor)
          : widget.baseColor;

  Color get _resolvedHighlight =>
      widget.highlightColor == WigglyDefaults.skeletonHighlightColor
          ? (_theme?.skeletonHighlightColor ?? widget.highlightColor)
          : widget.highlightColor;

  Widget _buildBlock({
    required double height,
    double? width,
    required double borderRadius,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = _controller.value * 2 * math.pi;
          return CustomPaint(
            size: Size.infinite,
            painter: WigglySkeletonPainter(
              phase: phase,
              travel: _controller.value,
              baseColor: _resolvedBase,
              highlightColor: _resolvedHighlight,
              borderRadius: borderRadius,
              waveAmplitude: _effectiveAmplitude(widget.waveAmplitude),
              waveLength: widget.waveLength,
              bandWidth: widget.bandWidth,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLines({double? widthOverride}) {
    final children = <Widget>[];
    for (var i = 0; i < widget._lines; i++) {
      final isLast = i == widget._lines - 1;
      final fraction = isLast ? widget._lastLineFraction : 1.0;
      final line = LayoutBuilder(
        builder: (context, constraints) {
          final maxW = widthOverride ?? constraints.maxWidth;
          return _buildBlock(
            height: widget._lineHeight,
            width: maxW * fraction,
            borderRadius: widget.borderRadius,
          );
        },
      );
      children.add(line);
      if (!isLast) {
        children.add(SizedBox(height: widget._lineSpacing));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticsLabel ?? 'Loading content';
    Widget child;
    switch (widget._variant) {
      case _SkeletonVariant.block:
        child = _buildBlock(
          height: widget.height,
          width: widget.width,
          borderRadius: widget.borderRadius,
        );
        break;
      case _SkeletonVariant.text:
        child = _buildLines();
        break;
      case _SkeletonVariant.card:
        child = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBlock(
              height: widget._avatarSize,
              width: widget._avatarSize,
              borderRadius: widget._avatarSize / 2,
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildLines()),
          ],
        );
        break;
    }

    return Semantics(
      container: true,
      label: label,
      child: child,
    );
  }
}
