import 'package:flutter/foundation.dart';

final ValueNotifier<bool> _debugWigglyLoadersNotifier =
    ValueNotifier<bool>(false);

/// Global debug toggle for wiggly math overlays.
bool get debugWigglyLoaders => _debugWigglyLoadersNotifier.value;

set debugWigglyLoaders(bool value) {
  _debugWigglyLoadersNotifier.value = value;
}

/// Listenable wrapper for reacting to [debugWigglyLoaders] changes.
ValueListenable<bool> get debugWigglyLoadersListenable =>
    _debugWigglyLoadersNotifier;
