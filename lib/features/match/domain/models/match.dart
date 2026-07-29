import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';

/// The top-level immutable aggregate root for a Stroke Wars match.
///
/// [Match] is the single source of truth for all gameplay state.
/// All changes are expressed as new [Match] instances via [copyWith].
class Match {
  /// Creates an immutable [Match].
  const Match({
    required this.id,
    required this.hostId,
    required this.configuration,
    required this.players,
    required this.rounds,
    required this.state,
    required this.createdAt,
    this.startedAt,
    this.result,
    this.currentRoundIndex = 0,
  });

  /// Creates a [Match] from a JSON map.
  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: MatchId(json['id'] as String),
    hostId: json['hostId'] as String,
    configuration: MatchConfiguration.fromJson(
      json['configuration'] as Map<String, dynamic>,
    ),
    players:
        (json['players'] as List<dynamic>)
            .map((p) => PlayerSlot.fromJson(p as Map<String, dynamic>))
            .toList(),
    rounds:
        (json['rounds'] as List<dynamic>)
            .map((r) => Round.fromJson(r as Map<String, dynamic>))
            .toList(),
    state: _stateFromJson(json['state'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    startedAt:
        json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
    result:
        json['result'] != null
            ? MatchResult.fromJson(json['result'] as Map<String, dynamic>)
            : null,
    currentRoundIndex: json['currentRoundIndex'] as int? ?? 0,
  );

  static MatchState _stateFromJson(String name) => switch (name) {
    'created' => const MatchCreatedState(),
    'waiting' => const MatchWaitingState(),
    'starting' => const MatchStartingState(),
    'wordSelection' => const WordSelectionState(),
    'drawing' => const DrawingState(),
    'guessing' => const GuessingState(),
    'roundFinished' => const RoundFinishedState(),
    'scoreboard' => const ScoreboardState(),
    'matchFinished' => const MatchFinishedState(),
    'cancelled' => const MatchCancelledState(),
    _ => const MatchCreatedState(),
  };

  static String _stateToJson(MatchState state) => switch (state) {
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

  /// Unique match identifier.
  final MatchId id;

  /// UUID of the player hosting this match.
  final String hostId;

  /// Full configuration for this match.
  final MatchConfiguration configuration;

  /// All player slots, including disconnected players.
  final List<PlayerSlot> players;

  /// All rounds (completed, current, and future).
  final List<Round> rounds;

  /// Current match lifecycle state.
  final MatchState state;

  /// When this match was first created.
  final DateTime createdAt;

  /// When the first round started.
  final DateTime? startedAt;

  /// Result, available only after match is finished.
  final MatchResult? result;

  /// Index into [rounds] for the active round.
  final int currentRoundIndex;

  /// Currently active round, or null if not yet started.
  Round? get currentRound =>
      rounds.isNotEmpty && currentRoundIndex < rounds.length
          ? rounds[currentRoundIndex]
          : null;

  /// Connected (active) players.
  List<PlayerSlot> get connectedPlayers =>
      players.where((p) => p.isConnected).toList();

  /// Returns the [PlayerSlot] for the given [slotId], or null.
  PlayerSlot? playerBySlotId(String slotId) =>
      players.where((p) => p.slotId == slotId).firstOrNull;

  /// Returns the [PlayerSlot] for the given [playerId], or null.
  PlayerSlot? playerByPlayerId(String playerId) =>
      players.where((p) => p.playerId == playerId).firstOrNull;

  /// Whether all required players have joined and are ready.
  bool get isReadyToStart =>
      connectedPlayers.length >= configuration.minPlayers &&
      connectedPlayers.every((p) => p.isReady);

  /// Returns a copy with the specified fields replaced.
  Match copyWith({
    MatchId? id,
    String? hostId,
    MatchConfiguration? configuration,
    List<PlayerSlot>? players,
    List<Round>? rounds,
    MatchState? state,
    DateTime? createdAt,
    DateTime? startedAt,
    MatchResult? result,
    int? currentRoundIndex,
  }) => Match(
    id: id ?? this.id,
    hostId: hostId ?? this.hostId,
    configuration: configuration ?? this.configuration,
    players: players ?? this.players,
    rounds: rounds ?? this.rounds,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt ?? this.startedAt,
    result: result ?? this.result,
    currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
  );

  /// Converts this [Match] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'id': id.value,
    'hostId': hostId,
    'configuration': configuration.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'state': _stateToJson(state),
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'result': result?.toJson(),
    'currentRoundIndex': currentRoundIndex,
  };

  @override
  bool operator ==(Object other) => other is Match && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Match(${id.value.substring(0, 8)}, state=${state.label}, '
      'players=${players.length}, rounds=${rounds.length})';
}
