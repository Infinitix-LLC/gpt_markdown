/// The arithmetic behind the streaming reveal.
///
/// Deliberately free of Flutter: it owns counters, the widget owns the
/// [Ticker] and calls `setState`. That split keeps the pacing rules — which
/// are the fiddly part — testable without pumping a widget.
///
/// Three behaviours a naive typewriter gets wrong, and this does not:
///
/// * **Lag adaptation.** A model can emit faster than the reveal speed. Left
///   alone the animation falls further behind for the whole reply. Whenever
///   the backlog would take longer than [maxLagSeconds] to clear, the reveal
///   speeds up to clear it in that window instead.
/// * **Fast-forward.** When the stream ends there is nothing left to wait
///   for, so the remainder lands within [fastForwardSeconds] rather than
///   trickling at the baseline rate.
/// * **Replacement.** A regenerate or branch switch replaces the text rather
///   than extending it, and must restart rather than continue from a
///   meaningless offset.
library;

import 'dart:math' as math;

/// Counters for a character-by-character reveal.
class RevealEngine {
  /// Longest the reveal may lag behind the text it has been given.
  static const double maxLagSeconds = 0.4;

  /// Window the remainder is revealed over once streaming has finished.
  static const double fastForwardSeconds = 0.15;

  double _revealed = 0;
  bool _fastForwarding = false;

  /// Characters revealed so far, fractional between characters.
  double get revealed => _revealed;

  /// Characters to show this frame.
  int get revealedFloor => _revealed.floor();

  /// Restarts from nothing — the text was replaced, not extended.
  void reset() {
    _revealed = 0;
    _fastForwarding = false;
  }

  /// Marks [length] characters revealed with no animation.
  void snapToEnd(int length) {
    _revealed = length.toDouble();
    _fastForwarding = false;
  }

  /// Clamps the reveal when the source shrank to a prefix of itself.
  void truncateTo(int length) {
    if (_revealed > length) {
      _revealed = length.toDouble();
    }
  }

  /// Enters the end-of-stream catch-up.
  void beginFastForward() => _fastForwarding = true;

  /// Leaves the catch-up because more text arrived after all.
  void clearFastForward() => _fastForwarding = false;

  /// Whether the reveal has caught up with [target].
  bool caughtUp(int target) => _revealed >= target;

  /// Advances by [dt] seconds toward [target] characters at
  /// [charactersPerSecond], adapting upward when behind.
  ///
  /// Returns false once the reveal has caught up — the caller's cue to stop
  /// its ticker and stop rebuilding.
  bool tick(double dt, int target, double charactersPerSecond) {
    var speed = charactersPerSecond;
    final backlog = target - _revealed;
    if (backlog > 0) {
      final window = _fastForwarding ? fastForwardSeconds : maxLagSeconds;
      speed = math.max(speed, backlog / window);
    }
    _revealed = math.min(_revealed + speed * dt, target.toDouble());
    if (_revealed >= target) {
      _fastForwarding = false;
      return false;
    }
    return true;
  }
}
