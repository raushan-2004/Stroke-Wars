import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';

/// Base class for all match domain commands.
///
/// Commands represent **user intent** — they describe what a player or host
/// *wants* to do. Commands are executed by [MatchController], which validates
/// them, mutates state, and emits [MatchEvent]s.
///
/// Never confuse commands with events:
/// - Commands = "I want to do X"
/// - Events   = "X happened"
sealed class MatchCommand {
  const MatchCommand();
}

// ─────────────────────────────────────────────────────────────────────────────
// Match lifecycle commands
// ─────────────────────────────────────────────────────────────────────────────

/// Create a new match with the given configuration.
class CreateMatchCommand extends MatchCommand {
  /// Creates a [CreateMatchCommand].
  const CreateMatchCommand({required this.hostId, required this.configuration});

  /// UUID of the host player.
  final String hostId;

  /// Configuration for the new match.
  final MatchConfiguration configuration;
}

/// A player joins an existing match.
class JoinMatchCommand extends MatchCommand {
  /// Creates a [JoinMatchCommand].
  const JoinMatchCommand({
    required this.matchId,
    required this.playerId,
    required this.displayName,
    this.avatarId = 'default',
  });

  /// The match to join.
  final MatchId matchId;

  /// UUID of the joining player.
  final String playerId;

  /// Display name at join time.
  final String displayName;

  /// Avatar identifier.
  final String avatarId;
}

/// A player leaves the match voluntarily.
class LeaveMatchCommand extends MatchCommand {
  /// Creates a [LeaveMatchCommand].
  const LeaveMatchCommand({required this.matchId, required this.playerId});

  /// The match being left.
  final MatchId matchId;

  /// UUID of the leaving player.
  final String playerId;
}

/// The host starts the match (moves from waiting/starting to first round).
class StartMatchCommand extends MatchCommand {
  /// Creates a [StartMatchCommand].
  const StartMatchCommand({required this.matchId, required this.hostId});

  /// The match to start.
  final MatchId matchId;

  /// UUID of the host issuing this command.
  final String hostId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Round commands
// ─────────────────────────────────────────────────────────────────────────────

/// Advance to the next round (or start the first round).
class StartRoundCommand extends MatchCommand {
  /// Creates a [StartRoundCommand].
  const StartRoundCommand({required this.matchId});

  /// The match advancing to the next round.
  final MatchId matchId;
}

/// The drawer has selected a word from the presented options.
class ChooseWordCommand extends MatchCommand {
  /// Creates a [ChooseWordCommand].
  const ChooseWordCommand({
    required this.matchId,
    required this.drawerId,
    required this.wordId,
  });

  /// The match this word was chosen in.
  final MatchId matchId;

  /// UUID of the player who is drawing.
  final String drawerId;

  /// ID of the chosen word.
  final String wordId;
}

/// A guesser submits a word guess.
class SubmitGuessCommand extends MatchCommand {
  /// Creates a [SubmitGuessCommand].
  const SubmitGuessCommand({
    required this.matchId,
    required this.playerId,
    required this.guessText,
  });

  /// The match the guess is submitted for.
  final MatchId matchId;

  /// UUID of the guessing player.
  final String playerId;

  /// The text they are guessing.
  final String guessText;
}

/// The current drawer's turn is skipped (e.g. disconnected).
class SkipTurnCommand extends MatchCommand {
  /// Creates a [SkipTurnCommand].
  const SkipTurnCommand({required this.matchId, required this.drawerId});

  /// The match the skip applies to.
  final MatchId matchId;

  /// UUID of the drawer being skipped.
  final String drawerId;
}

/// Force-end the current round (e.g. timer expired).
class EndRoundCommand extends MatchCommand {
  /// Creates an [EndRoundCommand].
  const EndRoundCommand({required this.matchId, this.reason = 'timer_expired'});

  /// The match whose round is ending.
  final MatchId matchId;

  /// Machine-readable reason (e.g. 'timer_expired', 'all_guessed').
  final String reason;
}

/// Conclude the entire match after all rounds are done.
class FinishMatchCommand extends MatchCommand {
  /// Creates a [FinishMatchCommand].
  const FinishMatchCommand({required this.matchId});

  /// The match to finish.
  final MatchId matchId;
}

/// Cancel the match before completion.
class CancelMatchCommand extends MatchCommand {
  /// Creates a [CancelMatchCommand].
  const CancelMatchCommand({required this.matchId, required this.reason});

  /// The match to cancel.
  final MatchId matchId;

  /// Human-readable reason for cancellation.
  final String reason;
}

/// A player confirms their readiness or toggles readiness status.
class ReadyPlayerCommand extends MatchCommand {
  /// Creates a [ReadyPlayerCommand].
  const ReadyPlayerCommand({
    required this.matchId,
    required this.playerId,
    required this.isReady,
  });

  /// The match ID.
  final MatchId matchId;

  /// UUID of the player toggling readiness.
  final String playerId;

  /// Readiness status flag.
  final bool isReady;
}

/// A dummy fallback match command used only when deserializing transition audits.
class DummyMatchCommand extends MatchCommand {
  const DummyMatchCommand(this.name);
  final String name;
}
