## 0.7.0

* Add `WigglySkeletonLoader` for shimmering skeleton placeholders — the highlight is a sinusoidal wave that **travels** across the shape instead of a flat gradient shimmer
  * `WigglySkeletonLoader(width, height, borderRadius)` for a single block
  * `WigglySkeletonLoader.text(lines, lineHeight, lastLineFraction)` for multi-line text placeholders
  * `WigglySkeletonLoader.card(avatarSize, lines)` for avatar + lines layout
* Add `WigglyProgressButton` — a button that morphs through `idle → loading → success/error` with a continuously wiggling outline
* Driven by a `WigglyButtonState` enum, exposes `onPressed`, `onComplete`, and per-state foregrounds
* Loading state hosts an inline `WigglyDotsLoader.indeterminate`
* Extend `WigglyLoadersThemeData` with `skeletonBaseColor`, `skeletonHighlightColor`, `buttonProgressColor`, `buttonForegroundColor`, `buttonSuccessColor`, `buttonErrorColor`
* Both new widgets respect shared `speedFactor`, `ease`, and `MediaQuery.disableAnimations` reduced-motion behavior
* Test coverage and README cookbook recipes for the new widgets

## 0.6.0

* Add `onComplete` callback to `WigglyLoader`, `WigglyLinearLoader`, and `WigglyDotsLoader` — fired once after the burst animation finishes when `progress` reaches `1.0`
* Add `completeDuration` parameter (default `450ms`) to control the burst animation length
* Burst effect: wiggle amplitude spikes to ×2.5 at the midpoint then elastically returns to baseline
* Reduced-motion mode skips the burst animation and calls `onComplete` directly
* Add optional `progressEndColor` to `WigglyLoader`, `WigglyLinearLoader`, `WigglyDotsLoader`, and `WigglyRefreshIndicator`
* Render gradient interpolation across arc and linear progress strokes with shader-based painting
* Interpolate active dot color from start to end across the row for determinate and indeterminate dots
* Update README, example app, and API docs to show gradient styling across all loader variants

## 0.5.0

* Add shared theme tokens to `WigglyLoadersThemeData` for `progressColor`, `trackColor`, `backgroundColor`, `sizeScale`, `strokeWidthScale`, `speedFactor`, and `ease`
* Apply shared theme styling and motion defaults across `WigglyLoader`, `WigglyLinearLoader`, `WigglyDotsLoader`, and `WigglyRefreshIndicator`
* Preserve widget-level overrides while allowing theme-driven presets for size, stroke, color, and animation feel
* Update README and example app to demonstrate the expanded theme engine
* Add test coverage for shared theme scaling and motion behavior

## 0.4.0

* Add `WigglyDotsLoader` for compact inline loading and progress states
* Add dots theming support in `WigglyLoadersThemeData`
* Add README cookbook recipes for cards, buttons, pagination, refresh, and themed usage
* Add tests for dots assertions, mode switching, theme resolution, reduced motion, and semantics

## 0.3.0

* Add package theme extension support via `WigglyLoadersThemeData`
* Add default semantics labels/values for loader, linear loader, and refresh indicator
* Add soft reduced-motion behavior when `MediaQuery.disableAnimations` is enabled
* Add `triggerDistance`, `maxDragDistance`, and `notificationPredicate` to `WigglyRefreshIndicator`
* Add test coverage for theme resolution, semantics, and new refresh indicator parameters

## 0.2.0

* Add `willAnimate` (default `true`) to `WigglyLoader` and `WigglyLinearLoader`
* Add mount intro animation: determinate `0 -> progress`, indeterminate intro `0 -> 100%` then loop

## 0.1.0

* Initial release
* `WigglyLoader` — circular arc loader with determinate and indeterminate modes
* `WigglyLinearLoader` — horizontal bar loader with determinate and indeterminate modes
* `WigglyRefreshIndicator` — pull-to-refresh wrapper with wiggly arc
