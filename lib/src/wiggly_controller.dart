import 'package:flutter/foundation.dart';

/// Playback state reported by [WigglyController].
enum WigglyControllerStatus {
  idle,
  playing,
  paused,
  completed,
}

typedef WigglyControllerStatusListener = void Function(
    WigglyControllerStatus status);

/// External handle for driving a wiggly loader.
///
/// A controller can:
/// - pause and resume internal animation
/// - override progress programmatically via [jumpTo]
/// - notify listeners when playback status changes, including completion
class WigglyController extends ChangeNotifier {
  Object? _owner;
  VoidCallback? _pauseCallback;
  VoidCallback? _resumeCallback;
  ValueChanged<double?>? _progressCallback;
  double? Function()? _progressReader;
  WigglyControllerStatus _status = WigglyControllerStatus.idle;
  double? _progressOverride;
  final List<WigglyControllerStatusListener> _statusListeners =
      <WigglyControllerStatusListener>[];

  /// Current playback status.
  WigglyControllerStatus get status => _status;

  /// `true` when attached to a widget.
  bool get isAttached => _owner != null;

  /// `true` when [jumpTo] has supplied a progress override.
  bool get hasProgressOverride => _progressOverride != null;

  /// Current effective progress, if available.
  double? get progress => _progressReader?.call() ?? _progressOverride;

  /// Pauses all internal animation loops.
  void pause() {
    _pauseCallback?.call();
    _updateStatus(WigglyControllerStatus.paused);
  }

  /// Resumes internal animation loops.
  void resume() {
    _resumeCallback?.call();
    _updateStatus(WigglyControllerStatus.playing);
  }

  /// Overrides widget progress with a programmatic value between `0.0` and `1.0`.
  void jumpTo(double progress) {
    assert(
      progress >= 0.0 && progress <= 1.0,
      'progress must be between 0.0 and 1.0',
    );

    _progressOverride = progress;
    _progressCallback?.call(progress);
    notifyListeners();
  }

  /// Clears a programmatic progress override and restores widget-driven progress.
  void clearProgress() {
    if (_progressOverride == null) {
      return;
    }

    _progressOverride = null;
    _progressCallback?.call(null);
    notifyListeners();
  }

  /// Registers a listener for playback state changes.
  void addStatusListener(WigglyControllerStatusListener listener) {
    _statusListeners.add(listener);
  }

  /// Removes a listener previously registered with [addStatusListener].
  void removeStatusListener(WigglyControllerStatusListener listener) {
    _statusListeners.remove(listener);
  }

  /// Used internally by loader widgets to attach lifecycle callbacks.
  void attach({
    required Object owner,
    required VoidCallback pause,
    required VoidCallback resume,
    required ValueChanged<double?> onProgressOverrideChanged,
    required double? Function() readProgress,
  }) {
    if (_owner != null && !identical(_owner, owner)) {
      throw StateError(
        'A WigglyController can only be attached to one loader at a time.',
      );
    }

    _owner = owner;
    _pauseCallback = pause;
    _resumeCallback = resume;
    _progressCallback = onProgressOverrideChanged;
    _progressReader = readProgress;
    onProgressOverrideChanged(_progressOverride);
    _updateStatus(
      _status == WigglyControllerStatus.paused
          ? WigglyControllerStatus.paused
          : WigglyControllerStatus.playing,
    );
  }

  /// Used internally by loader widgets to detach lifecycle callbacks.
  void detach(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }

    _owner = null;
    _pauseCallback = null;
    _resumeCallback = null;
    _progressCallback = null;
    _progressReader = null;
    _updateStatus(WigglyControllerStatus.idle);
  }

  /// Used internally by loader widgets to publish a completion event.
  void notifyCompleted() {
    _updateStatus(WigglyControllerStatus.completed);
  }

  /// Used internally by loader widgets to publish normal playback state.
  void notifyPlaying() {
    _updateStatus(WigglyControllerStatus.playing);
  }

  void _updateStatus(WigglyControllerStatus nextStatus) {
    if (_status == nextStatus) {
      return;
    }

    _status = nextStatus;
    notifyListeners();
    for (final listener in List<WigglyControllerStatusListener>.from(
      _statusListeners,
    )) {
      listener(nextStatus);
    }
  }
}
