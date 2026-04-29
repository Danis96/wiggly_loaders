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
