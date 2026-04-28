import 'package:flutter/material.dart';

/// Theme extension for package-level wiggly loader colors.
///
/// Add this to `ThemeData.extensions` to configure app-wide defaults while
/// still allowing per-widget overrides.
@immutable
class WigglyLoadersThemeData extends ThemeExtension<WigglyLoadersThemeData> {
  const WigglyLoadersThemeData({
    this.loaderProgressColor,
    this.loaderTrackColor,
    this.linearProgressColor,
    this.linearTrackColor,
    this.dotsProgressColor,
    this.dotsTrackColor,
    this.refreshProgressColor,
    this.refreshTrackColor,
    this.refreshBackgroundColor,
  });

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
  static WigglyLoadersThemeData? maybeOf(BuildContext context) {
    return Theme.of(context).extension<WigglyLoadersThemeData>();
  }
}
