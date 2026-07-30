/// Sealed hierarchy representing all expected failures in the match gameplay loop.
sealed class MatchFailure {
  const MatchFailure();
}

/// The state transition requested is not allowed under current state validation rules.
class InvalidTransitionFailure extends MatchFailure {
  const InvalidTransitionFailure(this.reason);
  final String reason;

  @override
  String toString() => 'InvalidTransitionFailure: $reason';
}

/// The specified player could not be found in the current match.
class PlayerNotFoundFailure extends MatchFailure {
  const PlayerNotFoundFailure(this.playerId);
  final String playerId;

  @override
  String toString() => 'PlayerNotFoundFailure: $playerId';
}

/// The chosen word is not present in the current round's word choices.
class WordUnavailableFailure extends MatchFailure {
  const WordUnavailableFailure(this.wordId);
  final String wordId;

  @override
  String toString() => 'WordUnavailableFailure: $wordId';
}

/// A round cannot be started because one is already in progress.
class RoundAlreadyRunningFailure extends MatchFailure {
  const RoundAlreadyRunningFailure();

  @override
  String toString() => 'RoundAlreadyRunningFailure';
}

/// A guess was submitted after the guessing timer had already expired.
class GuessTooLateFailure extends MatchFailure {
  const GuessTooLateFailure();

  @override
  String toString() => 'GuessTooLateFailure';
}

/// The operation failed because the timer has expired.
class TimerExpiredFailure extends MatchFailure {
  const TimerExpiredFailure();

  @override
  String toString() => 'TimerExpiredFailure';
}

/// The operation is disallowed because the match has already completed.
class MatchFinishedFailure extends MatchFailure {
  const MatchFinishedFailure();

  @override
  String toString() => 'MatchFinishedFailure';
}

/// The exact command was already processed (duplicate submission rejection).
class DuplicateCommandFailure extends MatchFailure {
  const DuplicateCommandFailure(this.commandId);
  final String commandId;

  @override
  String toString() => 'DuplicateCommandFailure: $commandId';
}

/// The player has already marked themselves as ready.
class PlayerAlreadyReadyFailure extends MatchFailure {
  const PlayerAlreadyReadyFailure(this.playerId);
  final String playerId;

  @override
  String toString() => 'PlayerAlreadyReadyFailure: $playerId';
}

/// The match cannot be started because not all players are ready or count is insufficient.
class MatchNotReadyFailure extends MatchFailure {
  const MatchNotReadyFailure(this.reason);
  final String reason;

  @override
  String toString() => 'MatchNotReadyFailure: $reason';
}

/// The configuration violates the rules engine constraints.
class ConfigurationInvalidFailure extends MatchFailure {
  const ConfigurationInvalidFailure(this.reason);
  final String reason;

  @override
  String toString() => 'ConfigurationInvalidFailure: $reason';
}

/// The command was not expected in the current state (e.g. choose word during waiting).
class UnexpectedCommandFailure extends MatchFailure {
  const UnexpectedCommandFailure(this.commandType, this.currentState);
  final String commandType;
  final String currentState;

  @override
  String toString() => 'UnexpectedCommandFailure: $commandType in state $currentState';
}
