/// The high-level lifecycle state of a [Match].
///
/// Transitions must be validated by [MatchValidator] before application.
///
/// Valid transition graph:
/// ```
/// created → waiting → starting → wordSelection
///                                    ↓
///                              drawing ↔ guessing
///                                    ↓
///                             roundFinished → scoreboard
///                                              ↓
///                                        matchFinished
/// * → cancelled (from any non-terminal state)
/// ```
sealed class MatchState {
  const MatchState();
}

/// Initial state after match creation — players not yet gathered.
class MatchCreatedState extends MatchState {
  const MatchCreatedState();
}

/// Lobby state — waiting for enough players to join and ready up.
class MatchWaitingState extends MatchState {
  const MatchWaitingState();
}

/// Countdown phase before the first round begins.
class MatchStartingState extends MatchState {
  const MatchStartingState();
}

/// The drawer is choosing a word from presented options.
class WordSelectionState extends MatchState {
  const WordSelectionState();
}

/// The active drawing phase — drawer is sketching.
class DrawingState extends MatchState {
  const DrawingState();
}

/// Guessing phase — players submit guesses; may overlap with drawing.
class GuessingState extends MatchState {
  const GuessingState();
}

/// The round has concluded; scores are being tallied.
class RoundFinishedState extends MatchState {
  const RoundFinishedState();
}

/// Scoreboard is displayed between rounds or at end of match.
class ScoreboardState extends MatchState {
  const ScoreboardState();
}

/// The match is complete — no more rounds remain.
class MatchFinishedState extends MatchState {
  const MatchFinishedState();
}

/// The match was cancelled before it could finish.
class MatchCancelledState extends MatchState {
  const MatchCancelledState();
}

/// Extension providing display utilities for [MatchState].
extension MatchStateLabel on MatchState {
  /// Returns a human-readable name for this state.
  String get label => switch (this) {
    MatchCreatedState() => 'Created',
    MatchWaitingState() => 'Waiting',
    MatchStartingState() => 'Starting',
    WordSelectionState() => 'Word Selection',
    DrawingState() => 'Drawing',
    GuessingState() => 'Guessing',
    RoundFinishedState() => 'Round Finished',
    ScoreboardState() => 'Scoreboard',
    MatchFinishedState() => 'Finished',
    MatchCancelledState() => 'Cancelled',
  };

  /// Returns true if this is a terminal state (no further transitions possible).
  bool get isTerminal =>
      this is MatchFinishedState || this is MatchCancelledState;

  /// Returns true if this is an active gameplay state.
  bool get isActive =>
      this is DrawingState ||
      this is GuessingState ||
      this is WordSelectionState;
}
