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
