import 'package:flutter/scheduler.dart';

/// Scheduler seam for the RSVP engine.
///
/// In production, [TickerScheduler] uses [Ticker] (Flutter) to drive ticks.
/// In tests, [FakeScheduler] advances manually — no real timers, instant tests.
abstract class RsvpScheduler {
  /// Called when the engine starts or resumes. [onTick] fires after [delay].
  void schedule(Duration delay, void Function() onTick);

  /// Cancel any pending tick.
  void cancel();

  /// Whether a tick is currently pending.
  bool get isScheduled;
}

/// Production scheduler backed by [Ticker].
class TickerScheduler implements RsvpScheduler {
  TickerScheduler(this._vsync);

  final TickerProvider _vsync;
  Ticker? _ticker;
  Duration _target = Duration.zero;
  void Function()? _callback;

  @override
  void schedule(Duration delay, void Function() onTick) {
    cancel();
    _target = delay;
    _callback = onTick;
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (elapsed >= _target) {
      final cb = _callback;
      cancel();
      cb?.call();
    }
  }

  @override
  void cancel() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _callback = null;
  }

  @override
  bool get isScheduled => _ticker != null;
}

/// Test scheduler that fires callbacks manually.
class FakeScheduler implements RsvpScheduler {
  bool _scheduled = false;
  void Function()? _pending;
  Duration _pendingDelay = Duration.zero;

  @override
  void schedule(Duration delay, void Function() onTick) {
    _scheduled = true;
    _pending = onTick;
    _pendingDelay = delay;
  }

  @override
  void cancel() {
    _scheduled = false;
    _pending = null;
  }

  @override
  bool get isScheduled => _scheduled;

  /// Fire the pending callback immediately (tests only).
  void fire() {
    final cb = _pending;
    _scheduled = false;
    _pending = null;
    cb?.call();
  }

  Duration get pendingDelay => _pendingDelay;
}
