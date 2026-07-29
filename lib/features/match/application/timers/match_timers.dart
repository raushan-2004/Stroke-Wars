import 'dart:async';

import 'package:stroke_wars/features/match/domain/models/timer_state.dart';

/// Stream-based round timer tracking the draw phase duration.
///
/// No Flutter timers. No widget lifecycle dependencies.
/// Emits immutable [TimerState] snapshots every second.
class RoundTimer {
  /// Creates a [RoundTimer] for the given [durationSecs].
  RoundTimer({required this.durationSecs});

  /// Total seconds this timer counts down from.
  final int durationSecs;

  final StreamController<TimerState> _controller =
      StreamController<TimerState>.broadcast();

  Timer? _timer;
  int _elapsed = 0;
  bool _paused = false;
  bool _disposed = false;

  /// Stream of [TimerState] snapshots (one per second while running).
  Stream<TimerState> get stream => _controller.stream;

  /// Current snapshot without subscribing to the stream.
  TimerState get current => TimerState(
    durationSecs: durationSecs,
    elapsedSecs: _elapsed,
    isRunning: _timer != null && !_paused,
    isPaused: _paused,
  );

  /// Starts the countdown. Emits an initial tick immediately.
  void start() {
    if (_disposed || _timer != null) return;
    _emit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      _elapsed++;
      _emit();
      if (_elapsed >= durationSecs) stop();
    });
  }

  /// Pauses the countdown without resetting elapsed time.
  void pause() {
    _paused = true;
    _emit();
  }

  /// Resumes a paused countdown.
  void resume() {
    _paused = false;
    _emit();
  }

  /// Stops the timer. Does not reset elapsed time.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _emit();
  }

  /// Stops the timer and resets elapsed time to zero.
  void reset() {
    stop();
    _elapsed = 0;
    _paused = false;
  }

  /// Stops the timer and releases stream resources.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }

  void _emit() {
    if (_disposed) return;
    _controller.add(current);
  }
}

/// Stream-based preparation timer for the countdown before a round begins.
class PreparationTimer {
  /// Creates a [PreparationTimer] with the given [durationSecs].
  PreparationTimer({this.durationSecs = 3});

  /// Countdown duration in seconds.
  final int durationSecs;

  final StreamController<TimerState> _controller =
      StreamController<TimerState>.broadcast();

  Timer? _timer;
  int _elapsed = 0;
  bool _disposed = false;

  /// Stream of [TimerState] snapshots during preparation countdown.
  Stream<TimerState> get stream => _controller.stream;

  /// Current snapshot.
  TimerState get current => TimerState(
    durationSecs: durationSecs,
    elapsedSecs: _elapsed,
    isRunning: _timer != null,
  );

  /// Starts the preparation countdown.
  void start() {
    if (_disposed || _timer != null) return;
    _emit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      _emit();
      if (_elapsed >= durationSecs) stop();
    });
  }

  /// Stops and resets the preparation timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Releases stream resources.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }

  void _emit() {
    if (_disposed) return;
    _controller.add(current);
  }
}

/// Stream-based scoreboard timer that auto-advances after display duration.
class ScoreboardTimer {
  /// Creates a [ScoreboardTimer] with the given [durationSecs].
  ScoreboardTimer({this.durationSecs = 5});

  /// How long the scoreboard is displayed before auto-advancing.
  final int durationSecs;

  final StreamController<TimerState> _controller =
      StreamController<TimerState>.broadcast();

  Timer? _timer;
  int _elapsed = 0;
  bool _disposed = false;

  /// Stream of [TimerState] snapshots during scoreboard display.
  Stream<TimerState> get stream => _controller.stream;

  /// Current snapshot.
  TimerState get current => TimerState(
    durationSecs: durationSecs,
    elapsedSecs: _elapsed,
    isRunning: _timer != null,
  );

  /// Starts the scoreboard auto-advance countdown.
  void start() {
    if (_disposed || _timer != null) return;
    _emit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      _emit();
      if (_elapsed >= durationSecs) stop();
    });
  }

  /// Stops the scoreboard timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Releases stream resources.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }

  void _emit() {
    if (_disposed) return;
    _controller.add(current);
  }
}
