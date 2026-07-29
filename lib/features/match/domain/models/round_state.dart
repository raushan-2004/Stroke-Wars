/// The lifecycle state of a single [Round].
sealed class RoundState {
  const RoundState();
}

/// Round has been created but not yet started.
class RoundIdleState extends RoundState {
  const RoundIdleState();
}

/// Preparation countdown is in progress before drawing begins.
class RoundPreparingState extends RoundState {
  const RoundPreparingState();
}

/// Round is actively running — drawing and guessing in progress.
class RoundActiveState extends RoundState {
  const RoundActiveState();
}

/// Round has completed normally.
class RoundFinishedRoundState extends RoundState {
  const RoundFinishedRoundState();
}

/// Round was cancelled (e.g. match cancelled, host left).
class RoundCancelledState extends RoundState {
  const RoundCancelledState();
}

/// Extension providing display utilities for [RoundState].
extension RoundStateLabel on RoundState {
  /// Returns a human-readable name for this state.
  String get label => switch (this) {
    RoundIdleState() => 'Idle',
    RoundPreparingState() => 'Preparing',
    RoundActiveState() => 'Active',
    RoundFinishedRoundState() => 'Finished',
    RoundCancelledState() => 'Cancelled',
  };

  /// Returns true if this round is still in progress.
  bool get isInProgress =>
      this is RoundPreparingState || this is RoundActiveState;

  /// Returns true if this round can no longer be modified.
  bool get isTerminal =>
      this is RoundFinishedRoundState || this is RoundCancelledState;
}
