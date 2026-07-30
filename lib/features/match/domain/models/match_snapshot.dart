import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';

/// Immutable snapshot of the complete match state at a point in time.
///
/// Used for:
/// - Local persistence between app sessions
/// - Replay playback
/// - Network synchronisation (future)
/// - Crash recovery
class MatchSnapshot {
  /// Schema version for forward-compatibility during deserialization.
  static const int currentVersion = 1;

  /// Creates an immutable [MatchSnapshot].
  const MatchSnapshot({
    required this.matchId,
    required this.capturedAt,
    required this.matchState,
    required this.players,
    required this.rounds,
    required this.configuration,
    this.version = currentVersion,
  });

  /// Creates a [MatchSnapshot] from a [Match] at the current instant.
  factory MatchSnapshot.from(Match match) => MatchSnapshot(
    matchId: match.id,
    capturedAt: DateTime.now(),
    matchState: _stateToString(match.state),
    players: List.unmodifiable(match.players),
    rounds: List.unmodifiable(match.rounds),
    configuration: match.configuration,
  );

  /// Creates a [MatchSnapshot] from a JSON map.
  factory MatchSnapshot.fromJson(Map<String, dynamic> json) => MatchSnapshot(
    matchId: MatchId(json['matchId'] as String),
    capturedAt: DateTime.parse(json['capturedAt'] as String),
    matchState: json['matchState'] as String,
    players: (json['players'] as List<dynamic>)
        .map((p) => PlayerSlot.fromJson(p as Map<String, dynamic>))
        .toList(),
    rounds: (json['rounds'] as List<dynamic>)
        .map((r) => Round.fromJson(r as Map<String, dynamic>))
        .toList(),
    configuration: MatchConfiguration.fromJson(
      json['configuration'] as Map<String, dynamic>,
    ),
    version: json['version'] as int? ?? currentVersion,
  );

  static String _stateToString(MatchState state) => switch (state) {
    MatchCreatedState() => 'created',
    MatchWaitingState() => 'waiting',
    MatchStartingState() => 'starting',
    WordSelectionState() => 'wordSelection',
    DrawingState() => 'drawing',
    GuessingState() => 'guessing',
    RoundFinishedState() => 'roundFinished',
    ScoreboardState() => 'scoreboard',
    MatchFinishedState() => 'matchFinished',
    MatchCancelledState() => 'cancelled',
  };

  /// The match this snapshot was taken from.
  final MatchId matchId;

  /// Timestamp when the snapshot was captured.
  final DateTime capturedAt;

  /// Serialized string representation of the [MatchState].
  final String matchState;

  /// Player slots at snapshot time.
  final List<PlayerSlot> players;

  /// All rounds at snapshot time.
  final List<Round> rounds;

  /// Configuration at snapshot time.
  final MatchConfiguration configuration;

  /// Schema version for forward-compatible deserialization.
  final int version;

  /// Converts this [MatchSnapshot] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'version': version,
    'matchId': matchId.value,
    'capturedAt': capturedAt.toIso8601String(),
    'matchState': matchState,
    'players': players.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'configuration': configuration.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is MatchSnapshot &&
      other.matchId == matchId &&
      other.capturedAt == capturedAt;

  @override
  int get hashCode => Object.hash(matchId, capturedAt);

  @override
  String toString() =>
      'MatchSnapshot(${matchId.value.substring(0, 8)}, '
      'at=${capturedAt.toIso8601String()}, state=$matchState)';
}
