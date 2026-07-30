import 'dart:async';

import 'package:stroke_wars/features/match/application/timers/match_timers.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';

/// Represents the active phase of the [MatchClock].
enum MatchClockType {
  /// Clock is not active.
  idle,

  /// Countdown before the round starts.
  preparation,

  /// Active drawing/guessing phase.
  round,

  /// Scoreboard display/intermission phase.
  scoreboard,
}

/// Immutable snapshot representing the unified state of the [MatchClock].
class MatchClockState {
  const MatchClockState({
    required this.type,
    required this.timerState,
  });

  /// The active phase of the clock.
  final MatchClockType type;

  /// Underlying timer progression details.
  final TimerState timerState;

  /// Whether the clock timer is currently running.
  bool get isRunning => timerState.isRunning;

  /// Whether the clock timer has reached zero.
  bool get isExpired => timerState.isExpired;

  /// Normalized progress from 0.0 to 1.0.
  double get progress => timerState.progress;

  @override
  String toString() => 'MatchClockState(type: ${type.name}, progress: $progress)';
}

/// A unified clock timer manager for a Stroke Wars match.
///
/// Decouples the UI from individual timers by providing a single source
/// of truth for all countdown sequences (preparation, drawing, and scoreboard).
class MatchClock {
  MatchClock() : _controller = StreamController<MatchClockState>.broadcast() {
    _state = const MatchClockState(
      type: MatchClockType.idle,
      timerState: TimerState(durationSecs: 0, elapsedSecs: 0, isRunning: false),
    );
  }

  final StreamController<MatchClockState> _controller;
  StreamSubscription<TimerState>? _sub;

  // Internal references to active timers for clean disposal
  PreparationTimer? _preparationTimer;
  RoundTimer? _roundTimer;
  ScoreboardTimer? _scoreboardTimer;

  late MatchClockState _state;
  bool _disposed = false;

  /// Live stream of unified [MatchClockState] ticks.
  Stream<MatchClockState> get stream => _controller.stream;

  /// The current snapshot state of the clock.
  MatchClockState get current => _state;

  /// Starts the 3-second preparation countdown.
  void startPreparation(int durationSecs, {void Function()? onComplete}) {
    _cancelActive();
    final timer = PreparationTimer(durationSecs: durationSecs);
    _preparationTimer = timer;

    _sub = timer.stream.listen((tick) {
      _update(MatchClockType.preparation, tick);
      if (tick.isExpired) {
        stop();
        if (onComplete != null) onComplete();
      }
    });
    timer.start();
  }

  /// Starts the active round timer (drawer sketching / players guessing).
  void startRound(int durationSecs, {void Function()? onComplete}) {
    _cancelActive();
    final timer = RoundTimer(durationSecs: durationSecs);
    _roundTimer = timer;

    _sub = timer.stream.listen((tick) {
      _update(MatchClockType.round, tick);
      if (tick.isExpired) {
        stop();
        if (onComplete != null) onComplete();
      }
    });
    timer.start();
  }

  /// Starts the scoreboard transition timer.
  void startScoreboard(int durationSecs, {void Function()? onComplete}) {
    _cancelActive();
    final timer = ScoreboardTimer(durationSecs: durationSecs);
    _scoreboardTimer = timer;

    _sub = timer.stream.listen((tick) {
      _update(MatchClockType.scoreboard, tick);
      if (tick.isExpired) {
        stop();
        if (onComplete != null) onComplete();
      }
    });
    timer.start();
  }

  /// Pauses the active round timer.
  void pause() {
    _roundTimer?.pause();
  }

  /// Resumes the active round timer.
  void resume() {
    _roundTimer?.resume();
  }

  /// Stops all active timers and resets the clock to idle.
  void stop() {
    _cancelActive();
    _update(
      MatchClockType.idle,
      const TimerState(durationSecs: 0, elapsedSecs: 0, isRunning: false),
    );
  }

  /// Releases resources.
  void dispose() {
    _disposed = true;
    _cancelActive();
    _controller.close();
  }

  void _cancelActive() {
    _sub?.cancel();
    _sub = null;

    _preparationTimer?.dispose();
    _preparationTimer = null;

    _roundTimer?.dispose();
    _roundTimer = null;

    _scoreboardTimer?.dispose();
    _scoreboardTimer = null;
  }

  void _update(MatchClockType type, TimerState timerState) {
    if (_disposed) return;
    _state = MatchClockState(type: type, timerState: timerState);
    _controller.add(_state);
  }
}
