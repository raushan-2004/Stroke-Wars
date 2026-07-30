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
  const MatchEvent({
    required this.matchId,
    required this.timestamp,
    this.roundId,
    this.sequenceNumber = 0,
    this.originPlayer,
    this.eventVersion = 1,
  });

  /// The match this event belongs to.
  final MatchId matchId;

  /// When this event occurred.
  final DateTime timestamp;

  /// Active round ID, if any.
  final String? roundId;

  /// Monotonically increasing sequence number assigned by SequenceGenerator.
  final int sequenceNumber;

  /// UUID of the player who triggered the event, or null if system/clock.
  final String? originPlayer;

  /// Schema version of the event for replay compatibility.
  final int eventVersion;

  /// Subclasses override this to provide specific JSON fields.
  Map<String, dynamic> toSpecificJson();

  /// Converts this event to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    ...toSpecificJson(),
    'matchId': matchId.value,
    'timestamp': timestamp.toIso8601String(),
    'roundId': roundId,
    'sequenceNumber': sequenceNumber,
    'originPlayer': originPlayer,
    'eventVersion': eventVersion,
  };

  /// Reconstructs a [MatchEvent] from a JSON map.
  static MatchEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final matchId = MatchId(json['matchId'] as String);
    final timestamp = DateTime.parse(json['timestamp'] as String);
    final roundId = json['roundId'] as String?;
    final sequenceNumber = json['sequenceNumber'] as int? ?? 0;
    final originPlayer = json['originPlayer'] as String?;
    final eventVersion = json['eventVersion'] as int? ?? 1;

    switch (type) {
      case 'match_created':
        return MatchCreatedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          hostId: json['hostId'] as String,
        );
      case 'match_started':
        return MatchStartedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
        );
      case 'match_ended':
        return MatchEndedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          winnerId: json['winnerId'] as String,
        );
      case 'match_cancelled':
        return MatchCancelledEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          reason: json['reason'] as String,
        );
      case 'player_joined':
        return PlayerJoinedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          playerId: json['playerId'] as String,
          displayName: json['displayName'] as String,
        );
      case 'player_left':
        return PlayerLeftEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          playerId: json['playerId'] as String,
        );
      case 'player_skipped':
        return PlayerSkippedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          playerId: json['playerId'] as String,
        );
      case 'player_readiness':
        return PlayerReadinessEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          playerId: json['playerId'] as String,
          isReady: json['isReady'] as bool,
        );
      case 'round_started':
        return RoundStartedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          roundNumber: json['roundNumber'] as int,
          drawerId: json['drawerId'] as String,
        );
      case 'round_ended':
        return RoundEndedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          roundNumber: json['roundNumber'] as int,
        );
      case 'word_chosen':
        return WordChosenEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          roundNumber: json['roundNumber'] as int,
          wordId: json['wordId'] as String,
        );
      case 'word_revealed':
        return WordRevealedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          roundNumber: json['roundNumber'] as int,
          wordText: json['wordText'] as String,
        );
      case 'guess_submitted':
        return GuessSubmittedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          playerId: json['playerId'] as String,
          guessText: json['guessText'] as String,
        );
      case 'correct_guess':
        return CorrectGuessEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          playerId: json['playerId'] as String,
          guessTimeMs: json['guessTimeMs'] as int,
          pointsAwarded: json['pointsAwarded'] as int,
        );
      case 'timer_tick':
        return TimerTickEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
          remainingSecs: json['remainingSecs'] as int,
        );
      case 'timer_expired':
        return TimerExpiredEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
        );
      case 'score_updated':
        return ScoreUpdatedEvent(
          matchId: matchId,
          timestamp: timestamp,
          roundId: roundId,
          sequenceNumber: sequenceNumber,
          originPlayer: originPlayer,
          eventVersion: eventVersion,
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
  const MatchCreatedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.hostId,
  });

  final String hostId;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'match_created',
    'hostId': hostId,
  };
}

/// The match transitioned from waiting/starting to active play.
class MatchStartedEvent extends MatchEvent {
  const MatchStartedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
  });

  @override
  Map<String, dynamic> toSpecificJson() => {'type': 'match_started'};
}

/// The match completed normally with a winner.
class MatchEndedEvent extends MatchEvent {
  const MatchEndedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.winnerId,
  });

  final String winnerId;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'match_ended',
    'winnerId': winnerId,
  };
}

/// The match was cancelled before completion.
class MatchCancelledEvent extends MatchEvent {
  const MatchCancelledEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.reason,
  });

  final String reason;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'match_cancelled',
    'reason': reason,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Player events
// ─────────────────────────────────────────────────────────────────────────────

/// A player successfully joined the match.
class PlayerJoinedEvent extends MatchEvent {
  const PlayerJoinedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
    required this.displayName,
  });

  final String playerId;
  final String displayName;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'player_joined',
    'playerId': playerId,
    'displayName': displayName,
  };
}

/// A player left or disconnected from the match.
class PlayerLeftEvent extends MatchEvent {
  const PlayerLeftEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
  });

  final String playerId;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'player_left',
    'playerId': playerId,
  };
}

/// A player's turn was skipped (disconnected or timed out).
class PlayerSkippedEvent extends MatchEvent {
  const PlayerSkippedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
  });

  final String playerId;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'player_skipped',
    'playerId': playerId,
  };
}

/// A player has toggled readiness state.
class PlayerReadinessEvent extends MatchEvent {
  const PlayerReadinessEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
    required this.isReady,
  });

  final String playerId;
  final bool isReady;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'player_readiness',
    'playerId': playerId,
    'isReady': isReady,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Round events
// ─────────────────────────────────────────────────────────────────────────────

/// A new round started.
class RoundStartedEvent extends MatchEvent {
  const RoundStartedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.roundNumber,
    required this.drawerId,
  });

  final int roundNumber;
  final String drawerId;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'round_started',
    'roundNumber': roundNumber,
    'drawerId': drawerId,
  };
}

/// A round concluded.
class RoundEndedEvent extends MatchEvent {
  const RoundEndedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.roundNumber,
  });

  final int roundNumber;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'round_ended',
    'roundNumber': roundNumber,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Word events
// ─────────────────────────────────────────────────────────────────────────────

/// The drawer chose a word.
class WordChosenEvent extends MatchEvent {
  const WordChosenEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.roundNumber,
    required this.wordId,
  });

  final int roundNumber;
  final String wordId;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'word_chosen',
    'roundNumber': roundNumber,
    'wordId': wordId,
  };
}

/// The word was revealed to all players at round end.
class WordRevealedEvent extends MatchEvent {
  const WordRevealedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.roundNumber,
    required this.wordText,
  });

  final int roundNumber;
  final String wordText;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'word_revealed',
    'roundNumber': roundNumber,
    'wordText': wordText,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Guess events
// ─────────────────────────────────────────────────────────────────────────────

/// A player submitted a guess attempt.
class GuessSubmittedEvent extends MatchEvent {
  const GuessSubmittedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
    required this.guessText,
  });

  final String playerId;
  final String guessText;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'guess_submitted',
    'playerId': playerId,
    'guessText': guessText,
  };
}

/// A player guessed correctly.
class CorrectGuessEvent extends MatchEvent {
  const CorrectGuessEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
    required this.guessTimeMs,
    required this.pointsAwarded,
  });

  final String playerId;
  final int guessTimeMs;
  final int pointsAwarded;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'correct_guess',
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
  const TimerTickEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.remainingSecs,
  });

  final int remainingSecs;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'timer_tick',
    'remainingSecs': remainingSecs,
  };
}

/// The active timer reached zero.
class TimerExpiredEvent extends MatchEvent {
  const TimerExpiredEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
  });

  @override
  Map<String, dynamic> toSpecificJson() => {'type': 'timer_expired'};
}

// ─────────────────────────────────────────────────────────────────────────────
// Score events
// ─────────────────────────────────────────────────────────────────────────────

/// A player's cumulative score was updated.
class ScoreUpdatedEvent extends MatchEvent {
  const ScoreUpdatedEvent({
    required super.matchId,
    required super.timestamp,
    super.roundId,
    super.sequenceNumber,
    super.originPlayer,
    super.eventVersion,
    required this.playerId,
    required this.newTotal,
  });

  final String playerId;
  final int newTotal;

  @override
  Map<String, dynamic> toSpecificJson() => {
    'type': 'score_updated',
    'playerId': playerId,
    'newTotal': newTotal,
  };
}
