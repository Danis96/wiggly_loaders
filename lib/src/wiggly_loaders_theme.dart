import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Theme extension for package-level wiggly loader styling.
///
/// Add this to `ThemeData.extensions` to configure app-wide defaults while
/// still allowing per-widget overrides.
@immutable
class WigglyLoadersThemeData extends ThemeExtension<WigglyLoadersThemeData> {
  const WigglyLoadersThemeData({
    this.progressColor,
    this.trackColor,
    this.backgroundColor,
    this.sizeScale,
    this.strokeWidthScale,
    this.speedFactor,
    this.ease,
    this.loaderProgressColor,
    this.loaderTrackColor,
    this.linearProgressColor,
    this.linearTrackColor,
    this.dotsProgressColor,
    this.dotsTrackColor,
    this.refreshProgressColor,
    this.refreshTrackColor,
    this.refreshBackgroundColor,
  })  : assert(sizeScale == null || sizeScale > 0, 'sizeScale must be > 0'),
        assert(
          strokeWidthScale == null || strokeWidthScale > 0,
          'strokeWidthScale must be > 0',
        ),
        assert(
          speedFactor == null || speedFactor > 0,
          'speedFactor must be > 0',
        );

  final Color? progressColor;
  final Color? trackColor;
  final Color? backgroundColor;
  final double? sizeScale;
  final double? strokeWidthScale;
  final double? speedFactor;
  final Curve? ease;

  final Color? loaderProgressColor;
  final Color? loaderTrackColor;
  final Color? linearProgressColor;
  final Color? linearTrackColor;
  final Color? dotsProgressColor;
  final Color? dotsTrackColor;
  final Color? refreshProgressColor;
  final Color? refreshTrackColor;
  final Color? refreshBackgroundColor;

  @override
  WigglyLoadersThemeData copyWith({
    Color? progressColor,
    Color? trackColor,
    Color? backgroundColor,
    double? sizeScale,
    double? strokeWidthScale,
    double? speedFactor,
    Curve? ease,
    Color? loaderProgressColor,
    Color? loaderTrackColor,
    Color? linearProgressColor,
    Color? linearTrackColor,
    Color? dotsProgressColor,
    Color? dotsTrackColor,
    Color? refreshProgressColor,
    Color? refreshTrackColor,
    Color? refreshBackgroundColor,
  }) {
    return WigglyLoadersThemeData(
      progressColor: progressColor ?? this.progressColor,
      trackColor: trackColor ?? this.trackColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      sizeScale: sizeScale ?? this.sizeScale,
      strokeWidthScale: strokeWidthScale ?? this.strokeWidthScale,
      speedFactor: speedFactor ?? this.speedFactor,
      ease: ease ?? this.ease,
      loaderProgressColor: loaderProgressColor ?? this.loaderProgressColor,
      loaderTrackColor: loaderTrackColor ?? this.loaderTrackColor,
      linearProgressColor: linearProgressColor ?? this.linearProgressColor,
      linearTrackColor: linearTrackColor ?? this.linearTrackColor,
      dotsProgressColor: dotsProgressColor ?? this.dotsProgressColor,
      dotsTrackColor: dotsTrackColor ?? this.dotsTrackColor,
      refreshProgressColor: refreshProgressColor ?? this.refreshProgressColor,
      refreshTrackColor: refreshTrackColor ?? this.refreshTrackColor,
      refreshBackgroundColor:
          refreshBackgroundColor ?? this.refreshBackgroundColor,
    );
  }

  @override
  WigglyLoadersThemeData lerp(
    covariant ThemeExtension<WigglyLoadersThemeData>? other,
    double t,
  ) {
    if (other is! WigglyLoadersThemeData) {
      return this;
    }

    return WigglyLoadersThemeData(
      progressColor: Color.lerp(progressColor, other.progressColor, t),
      trackColor: Color.lerp(trackColor, other.trackColor, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      sizeScale: lerpDouble(sizeScale, other.sizeScale, t),
      strokeWidthScale: lerpDouble(strokeWidthScale, other.strokeWidthScale, t),
      speedFactor: lerpDouble(speedFactor, other.speedFactor, t),
      ease: t < 0.5 ? ease : other.ease,
      loaderProgressColor:
          Color.lerp(loaderProgressColor, other.loaderProgressColor, t),
      loaderTrackColor: Color.lerp(loaderTrackColor, other.loaderTrackColor, t),
      linearProgressColor:
          Color.lerp(linearProgressColor, other.linearProgressColor, t),
      linearTrackColor: Color.lerp(linearTrackColor, other.linearTrackColor, t),
      dotsProgressColor:
          Color.lerp(dotsProgressColor, other.dotsProgressColor, t),
      dotsTrackColor: Color.lerp(dotsTrackColor, other.dotsTrackColor, t),
      refreshProgressColor:
          Color.lerp(refreshProgressColor, other.refreshProgressColor, t),
      refreshTrackColor:
          Color.lerp(refreshTrackColor, other.refreshTrackColor, t),
      refreshBackgroundColor:
          Color.lerp(refreshBackgroundColor, other.refreshBackgroundColor, t),
    );
  }
}

class WigglyLoadersTheme {
  const WigglyLoadersTheme._();

  static WigglyLoadersThemeData? maybeOf(BuildContext context) {
    return Theme.of(context).extension<WigglyLoadersThemeData>();
  }
}
