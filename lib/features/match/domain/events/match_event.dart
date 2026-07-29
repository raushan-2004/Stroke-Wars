import 'package:stroke_wars/features/match/domain/models/match_id.dart';

/// Base class for all match domain events.
///
/// Events represent **completed facts** about what happened in the match.
/// They are the output of [MatchController] and are consumed by:
/// - Replay engine
/// - Networking layer (future)
/// - Analytics (future)
/// - Achievements (future)
/// - Persistence layer
///
/// Never confuse [MatchEvent] with [MatchCommand]. Commands express intent;
/// events express completed history.
sealed class MatchEvent {
  /// Creates a [MatchEvent].
  const MatchEvent({required this.matchId, required this.timestamp});

  /// The match this event belongs to.
  final MatchId matchId;

  /// When this event occurred.
  final DateTime timestamp;

  /// Converts this event to a JSON-serializable map.
  Map<String, dynamic> toJson();

  /// Reconstructs a [MatchEvent] from a JSON map.
  static MatchEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final matchId = MatchId(json['matchId'] as String);
    final timestamp = DateTime.parse(json['timestamp'] as String);
    switch (type) {
      case 'match_created':
        return MatchCreatedEvent(
          matchId: matchId,
          timestamp: timestamp,
          hostId: json['hostId'] as String,
        );
      case 'match_started':
        return MatchStartedEvent(matchId: matchId, timestamp: timestamp);
      case 'match_ended':
        return MatchEndedEvent(
          matchId: matchId,
          timestamp: timestamp,
          winnerId: json['winnerId'] as String,
        );
      case 'match_cancelled':
        return MatchCancelledEvent(
          matchId: matchId,
          timestamp: timestamp,
          reason: json['reason'] as String,
        );
      case 'player_joined':
        return PlayerJoinedEvent(
          matchId: matchId,
          timestamp: timestamp,
          playerId: json['playerId'] as String,
          displayName: json['displayName'] as String,
        );
      case 'player_left':
        return PlayerLeftEvent(
          matchId: matchId,
          timestamp: timestamp,
          playerId: json['playerId'] as String,
        );
      case 'player_skipped':
        return PlayerSkippedEvent(
          matchId: matchId,
          timestamp: timestamp,
          playerId: json['playerId'] as String,
        );
      case 'round_started':
        return RoundStartedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundNumber: json['roundNumber'] as int,
          drawerId: json['drawerId'] as String,
        );
      case 'round_ended':
        return RoundEndedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundNumber: json['roundNumber'] as int,
        );
      case 'word_chosen':
        return WordChosenEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundNumber: json['roundNumber'] as int,
          wordId: json['wordId'] as String,
        );
      case 'word_revealed':
        return WordRevealedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundNumber: json['roundNumber'] as int,
          wordText: json['wordText'] as String,
        );
      case 'guess_submitted':
        return GuessSubmittedEvent(
          matchId: matchId,
          timestamp: timestamp,
          playerId: json['playerId'] as String,
          guessText: json['guessText'] as String,
        );
      case 'correct_guess':
        return CorrectGuessEvent(
          matchId: matchId,
          timestamp: timestamp,
          playerId: json['playerId'] as String,
          guessTimeMs: json['guessTimeMs'] as int,
          pointsAwarded: json['pointsAwarded'] as int,
        );
      case 'timer_tick':
        return TimerTickEvent(
          matchId: matchId,
          timestamp: timestamp,
          remainingSecs: json['remainingSecs'] as int,
        );
      case 'timer_expired':
        return TimerExpiredEvent(matchId: matchId, timestamp: timestamp);
      case 'score_updated':
        return ScoreUpdatedEvent(
          matchId: matchId,
          timestamp: timestamp,
          playerId: json['playerId'] as String,
          newTotal: json['newTotal'] as int,
        );
      default:
        throw ArgumentError('Unknown match event type: $type');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Match lifecycle events
// ─────────────────────────────────────────────────────────────────────────────

/// A new match was created.
class MatchCreatedEvent extends MatchEvent {
  /// Creates a [MatchCreatedEvent].
  const MatchCreatedEvent({
    required super.matchId,
    required super.timestamp,
    required this.hostId,
  });

  /// UUID of the creating host.
  final String hostId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'match_created',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'hostId': hostId,
  };
}

/// The match transitioned from waiting/starting to active play.
class MatchStartedEvent extends MatchEvent {
  /// Creates a [MatchStartedEvent].
  const MatchStartedEvent({required super.matchId, required super.timestamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'match_started',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// The match completed normally with a winner.
class MatchEndedEvent extends MatchEvent {
  /// Creates a [MatchEndedEvent].
  const MatchEndedEvent({
    required super.matchId,
    required super.timestamp,
    required this.winnerId,
  });

  /// UUID of the winning player.
  final String winnerId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'match_ended',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'winnerId': winnerId,
  };
}

/// The match was cancelled before completion.
class MatchCancelledEvent extends MatchEvent {
  /// Creates a [MatchCancelledEvent].
  const MatchCancelledEvent({
    required super.matchId,
    required super.timestamp,
    required this.reason,
  });

  /// Human-readable reason for cancellation.
  final String reason;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'match_cancelled',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Player events
// ─────────────────────────────────────────────────────────────────────────────

/// A player successfully joined the match.
class PlayerJoinedEvent extends MatchEvent {
  /// Creates a [PlayerJoinedEvent].
  const PlayerJoinedEvent({
    required super.matchId,
    required super.timestamp,
    required this.playerId,
    required this.displayName,
  });

  /// UUID of the joining player.
  final String playerId;

  /// Display name of the joining player.
  final String displayName;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'player_joined',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
    'displayName': displayName,
  };
}

/// A player left or disconnected from the match.
class PlayerLeftEvent extends MatchEvent {
  /// Creates a [PlayerLeftEvent].
  const PlayerLeftEvent({
    required super.matchId,
    required super.timestamp,
    required this.playerId,
  });

  /// UUID of the departing player.
  final String playerId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'player_left',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
  };
}

/// A player's turn was skipped (disconnected or timed out).
class PlayerSkippedEvent extends MatchEvent {
  /// Creates a [PlayerSkippedEvent].
  const PlayerSkippedEvent({
    required super.matchId,
    required super.timestamp,
    required this.playerId,
  });

  /// UUID of the skipped player.
  final String playerId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'player_skipped',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Round events
// ─────────────────────────────────────────────────────────────────────────────

/// A new round started.
class RoundStartedEvent extends MatchEvent {
  /// Creates a [RoundStartedEvent].
  const RoundStartedEvent({
    required super.matchId,
    required super.timestamp,
    required this.roundNumber,
    required this.drawerId,
  });

  /// 1-based round number.
  final int roundNumber;

  /// UUID of the player drawing this round.
  final String drawerId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'round_started',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'roundNumber': roundNumber,
    'drawerId': drawerId,
  };
}

/// A round concluded.
class RoundEndedEvent extends MatchEvent {
  /// Creates a [RoundEndedEvent].
  const RoundEndedEvent({
    required super.matchId,
    required super.timestamp,
    required this.roundNumber,
  });

  /// 1-based round number.
  final int roundNumber;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'round_ended',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'roundNumber': roundNumber,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Word events
// ─────────────────────────────────────────────────────────────────────────────

/// The drawer chose a word.
class WordChosenEvent extends MatchEvent {
  /// Creates a [WordChosenEvent].
  const WordChosenEvent({
    required super.matchId,
    required super.timestamp,
    required this.roundNumber,
    required this.wordId,
  });

  /// Round this word was chosen for.
  final int roundNumber;

  /// ID of the chosen word.
  final String wordId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'word_chosen',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'roundNumber': roundNumber,
    'wordId': wordId,
  };
}

/// The word was revealed to all players at round end.
class WordRevealedEvent extends MatchEvent {
  /// Creates a [WordRevealedEvent].
  const WordRevealedEvent({
    required super.matchId,
    required super.timestamp,
    required this.roundNumber,
    required this.wordText,
  });

  /// Round this word was drawn in.
  final int roundNumber;

  /// The full word text (revealed post-round).
  final String wordText;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'word_revealed',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'roundNumber': roundNumber,
    'wordText': wordText,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Guess events
// ─────────────────────────────────────────────────────────────────────────────

/// A player submitted a guess attempt.
class GuessSubmittedEvent extends MatchEvent {
  /// Creates a [GuessSubmittedEvent].
  const GuessSubmittedEvent({
    required super.matchId,
    required super.timestamp,
    required this.playerId,
    required this.guessText,
  });

  /// UUID of the guessing player.
  final String playerId;

  /// The text they submitted.
  final String guessText;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'guess_submitted',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
    'guessText': guessText,
  };
}

/// A player guessed correctly.
class CorrectGuessEvent extends MatchEvent {
  /// Creates a [CorrectGuessEvent].
  const CorrectGuessEvent({
    required super.matchId,
    required super.timestamp,
    required this.playerId,
    required this.guessTimeMs,
    required this.pointsAwarded,
  });

  /// UUID of the player who guessed correctly.
  final String playerId;

  /// Time elapsed from round start in milliseconds.
  final int guessTimeMs;

  /// Points awarded for this correct guess.
  final int pointsAwarded;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'correct_guess',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
    'guessTimeMs': guessTimeMs,
    'pointsAwarded': pointsAwarded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Timer events
// ─────────────────────────────────────────────────────────────────────────────

/// One second elapsed on the active timer.
class TimerTickEvent extends MatchEvent {
  /// Creates a [TimerTickEvent].
  const TimerTickEvent({
    required super.matchId,
    required super.timestamp,
    required this.remainingSecs,
  });

  /// Remaining seconds on the timer.
  final int remainingSecs;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'timer_tick',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'remainingSecs': remainingSecs,
  };
}

/// The active timer reached zero.
class TimerExpiredEvent extends MatchEvent {
  /// Creates a [TimerExpiredEvent].
  const TimerExpiredEvent({required super.matchId, required super.timestamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'timer_expired',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Score events
// ─────────────────────────────────────────────────────────────────────────────

/// A player's cumulative score was updated.
class ScoreUpdatedEvent extends MatchEvent {
  /// Creates a [ScoreUpdatedEvent].
  const ScoreUpdatedEvent({
    required super.matchId,
    required super.timestamp,
    required this.playerId,
    required this.newTotal,
  });

  /// UUID of the player whose score changed.
  final String playerId;

  /// New cumulative total score.
  final int newTotal;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'score_updated',
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'playerId': playerId,
    'newTotal': newTotal,
  };
}
