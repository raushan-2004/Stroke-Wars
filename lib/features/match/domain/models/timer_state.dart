/// Immutable snapshot of a timer at a point in time.
///
/// Timers emit [TimerState] snapshots rather than mutating values,
/// keeping all consumers stateless.
class TimerState {
  /// Creates an immutable [TimerState].
  const TimerState({
    required this.durationSecs,
    required this.elapsedSecs,
    this.isRunning = false,
    this.isPaused = false,
  });

  /// Creates a [TimerState] from a JSON map.
  factory TimerState.fromJson(Map<String, dynamic> json) => TimerState(
    durationSecs: json['durationSecs'] as int,
    elapsedSecs: json['elapsedSecs'] as int,
    isRunning: json['isRunning'] as bool? ?? false,
    isPaused: json['isPaused'] as bool? ?? false,
  );

  /// Creates a fresh timer that has not started yet.
  factory TimerState.initial(int durationSecs) =>
      TimerState(durationSecs: durationSecs, elapsedSecs: 0);

  /// Total duration in seconds.
  final int durationSecs;

  /// How many seconds have elapsed since the timer started.
  final int elapsedSecs;

  /// Whether the timer is currently counting down.
  final bool isRunning;

  /// Whether the timer is temporarily paused.
  final bool isPaused;

  /// Remaining seconds, clamped to [0, durationSecs].
  int get remainingSecs => (durationSecs - elapsedSecs).clamp(0, durationSecs);

  /// True when elapsed time has reached or exceeded the duration.
  bool get isExpired => elapsedSecs >= durationSecs;

  /// Progress from 0.0 (not started) to 1.0 (complete).
  double get progress =>
      durationSecs > 0 ? (elapsedSecs / durationSecs).clamp(0.0, 1.0) : 0.0;

  /// Returns a copy with the specified fields replaced.
  TimerState copyWith({
    int? durationSecs,
    int? elapsedSecs,
    bool? isRunning,
    bool? isPaused,
  }) => TimerState(
    durationSecs: durationSecs ?? this.durationSecs,
    elapsedSecs: elapsedSecs ?? this.elapsedSecs,
    isRunning: isRunning ?? this.isRunning,
    isPaused: isPaused ?? this.isPaused,
  );

  /// Converts this [TimerState] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'durationSecs': durationSecs,
    'elapsedSecs': elapsedSecs,
    'isRunning': isRunning,
    'isPaused': isPaused,
  };

  @override
  bool operator ==(Object other) =>
      other is TimerState &&
      other.durationSecs == durationSecs &&
      other.elapsedSecs == elapsedSecs &&
      other.isRunning == isRunning &&
      other.isPaused == isPaused;

  @override
  int get hashCode =>
      Object.hash(durationSecs, elapsedSecs, isRunning, isPaused);

  @override
  String toString() =>
      'TimerState(${remainingSecs}s remaining, running=$isRunning)';
}
