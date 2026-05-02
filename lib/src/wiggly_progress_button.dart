import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'internal/wiggly_button_painter.dart';
import 'internal/wiggly_defaults.dart';
import 'wiggly_dots_loader.dart';
import 'wiggly_loaders_theme.dart';

/// Lifecycle states for [WigglyProgressButton].
enum WigglyButtonState { idle, loading, success, error }

/// A single, self-animating button that morphs through
/// `idle → loading → success / error` while its whole shape wiggles.
///
/// ```dart
/// WigglyProgressButton(
///   state: _state,
///   onPressed: () async {
///     setState(() => _state = WigglyButtonState.loading);
///     try {
///       await submit();
///       setState(() => _state = WigglyButtonState.success);
///     } catch (_) {
///       setState(() => _state = WigglyButtonState.error);
///     }
///   },
///   child: const Text('Submit'),
/// )
/// ```
class WigglyProgressButton extends StatefulWidget {
  const WigglyProgressButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.child,
    this.successChild,
    this.errorChild,
    this.width = 200.0,
    this.height = 52.0,
    this.borderRadius = 26.0,
    this.progressColor = WigglyDefaults.buttonProgressColor,
    this.foregroundColor = WigglyDefaults.buttonForegroundColor,
    this.successColor = WigglyDefaults.buttonSuccessColor,
    this.errorColor = WigglyDefaults.buttonErrorColor,
    this.wiggleAmplitude = 1.6,
    this.wiggleCount = 18,
    this.wiggleDuration = const Duration(milliseconds: 1600),
    this.morphDuration = const Duration(milliseconds: 360),
    this.onComplete,
  })  : assert(width > 0, 'width must be > 0'),
        assert(height > 0, 'height must be > 0'),
        assert(borderRadius >= 0, 'borderRadius must be >= 0'),
        assert(wiggleAmplitude >= 0, 'wiggleAmplitude must be >= 0'),
        assert(wiggleCount > 0, 'wiggleCount must be > 0');

  /// Current logical state. Drive this from your own code.
  final WigglyButtonState state;

  /// Called only when [state] is [WigglyButtonState.idle].
  final VoidCallback? onPressed;

  /// Label shown in idle state.
  final Widget child;

  /// Optional content for the success state. Defaults to a check icon.
  final Widget? successChild;

  /// Optional content for the error state. Defaults to a close icon.
  final Widget? errorChild;

  final double width;
  final double height;
  final double borderRadius;

  /// Fill color used in idle and loading states.
  final Color progressColor;

  /// Color used for the label / icon foreground.
  final Color foregroundColor;

  /// Fill color in the success state.
  final Color successColor;

  /// Fill color in the error state.
  final Color errorColor;

  final double wiggleAmplitude;
  final int wiggleCount;
  final Duration wiggleDuration;

  /// Duration of the width/color morph between states.
  final Duration morphDuration;

  /// Fired once when transitioning into [WigglyButtonState.success].
  final VoidCallback? onComplete;

  @override
  State<WigglyProgressButton> createState() => _WigglyProgressButtonState();
}

class _WigglyProgressButtonState extends State<WigglyProgressButton>
    with TickerProviderStateMixin {
  static const Duration _defaultWiggleDuration = Duration(milliseconds: 1600);
  static const double _reducedMotionDurationScale = 1.8;
  static const double _reducedMotionAmplitudeScale = 0.5;

  late final AnimationController _wiggleController;
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
      _wiggleController.duration = _effectiveDuration(widget.wiggleDuration);
      _wiggleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WigglyProgressButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wiggleDuration != widget.wiggleDuration) {
      _wiggleController.duration = _effectiveDuration(widget.wiggleDuration);
      _wiggleController.repeat();
    }

    if (oldWidget.state != widget.state &&
        widget.state == WigglyButtonState.success) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  Duration _effectiveDuration(Duration duration) {
    final speedFactor = _theme?.speedFactor;
    var resolved = duration;
    if (duration == _defaultWiggleDuration &&
        speedFactor != null &&
        speedFactor != 1.0) {
      resolved = Duration(
        microseconds: (duration.inMicroseconds / speedFactor).round(),
      );
    }
    if (_reduceMotion) {
      resolved = Duration(
        microseconds:
            (resolved.inMicroseconds * _reducedMotionDurationScale).round(),
      );
    }
    return resolved;
  }

  double _effectiveAmplitude() {
    return _reduceMotion
        ? widget.wiggleAmplitude * _reducedMotionAmplitudeScale
        : widget.wiggleAmplitude;
  }

  Color get _resolvedProgressColor =>
      widget.progressColor == WigglyDefaults.buttonProgressColor
          ? (_theme?.buttonProgressColor ??
              _theme?.progressColor ??
              widget.progressColor)
          : widget.progressColor;

  Color get _resolvedForeground =>
      widget.foregroundColor == WigglyDefaults.buttonForegroundColor
          ? (_theme?.buttonForegroundColor ?? widget.foregroundColor)
          : widget.foregroundColor;

  Color get _resolvedSuccess =>
      widget.successColor == WigglyDefaults.buttonSuccessColor
          ? (_theme?.buttonSuccessColor ?? widget.successColor)
          : widget.successColor;

  Color get _resolvedError =>
      widget.errorColor == WigglyDefaults.buttonErrorColor
          ? (_theme?.buttonErrorColor ?? widget.errorColor)
          : widget.errorColor;

  Color _fillForState(WigglyButtonState state) {
    switch (state) {
      case WigglyButtonState.idle:
      case WigglyButtonState.loading:
        return _resolvedProgressColor;
      case WigglyButtonState.success:
        return _resolvedSuccess;
      case WigglyButtonState.error:
        return _resolvedError;
    }
  }

  double _targetWidth() {
    switch (widget.state) {
      case WigglyButtonState.idle:
        return widget.width;
      case WigglyButtonState.loading:
      case WigglyButtonState.success:
      case WigglyButtonState.error:
        return widget.height;
    }
  }

  Widget _foregroundForState() {
    final fg = _resolvedForeground;
    switch (widget.state) {
      case WigglyButtonState.idle:
        return DefaultTextStyle.merge(
          style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          child: IconTheme.merge(
            data: IconThemeData(color: fg),
            child: widget.child,
          ),
        );
      case WigglyButtonState.loading:
        return WigglyDotsLoader.indeterminate(
          dotSize: math.max(widget.height * 0.16, 5.0),
          spacing: math.max(widget.height * 0.10, 4.0),
          progressColor: fg,
          trackColor: fg.withValues(alpha: 0.35),
        );
      case WigglyButtonState.success:
        return widget.successChild ?? Icon(Icons.check_rounded, color: fg, size: widget.height * 0.5);
      case WigglyButtonState.error:
        return widget.errorChild ?? Icon(Icons.close_rounded, color: fg, size: widget.height * 0.5);
    }
  }

  void _handleTap() {
    if (widget.state == WigglyButtonState.idle && widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = _fillForState(widget.state);
    final isInteractive =
        widget.state == WigglyButtonState.idle && widget.onPressed != null;

    final semanticsLabel = switch (widget.state) {
      WigglyButtonState.idle => 'Submit',
      WigglyButtonState.loading => 'Loading',
      WigglyButtonState.success => 'Success',
      WigglyButtonState.error => 'Error',
    };

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: semanticsLabel,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: widget.width, end: _targetWidth()),
        duration: widget.morphDuration,
        curve: _theme?.ease ?? Curves.easeOutCubic,
        builder: (context, animatedWidth, _) {
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: fill),
            duration: widget.morphDuration,
            builder: (context, animatedFill, __) {
              final activeFill = animatedFill ?? fill;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isInteractive ? _handleTap : null,
                child: SizedBox(
                  width: animatedWidth,
                  height: widget.height,
                  child: AnimatedBuilder(
                    animation: _wiggleController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: WigglyButtonPainter(
                          phase: _wiggleController.value * 2 * math.pi,
                          fillColor: activeFill,
                          strokeColor: null,
                          borderRadius: math.min(
                            widget.borderRadius,
                            widget.height / 2,
                          ),
                          waveAmplitude: _effectiveAmplitude(),
                          waveCount: widget.wiggleCount,
                          strokeWidth: 0,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: widget.morphDuration,
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey(widget.state),
                              child: _foregroundForState(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
