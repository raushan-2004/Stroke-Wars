import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/score.dart';
import 'package:stroke_wars/features/match/domain/models/state_transition.dart';

/// The top-level immutable aggregate root for a Stroke Wars match.
///
/// [Match] is the single source of truth for all gameplay state and audit history.
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
    this.commandHistory = const [],
    this.eventHistory = const [],
    this.transitionHistory = const [],
    this.turnHistory = const [],
    this.scoreHistory = const [],
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
    commandHistory: (json['commandHistory'] as List<dynamic>?)
            ?.map((c) => _commandFromJson(c as Map<String, dynamic>))
            .toList() ??
        const [],
    eventHistory: (json['eventHistory'] as List<dynamic>?)
            ?.map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    transitionHistory: (json['transitionHistory'] as List<dynamic>?)
            ?.map((t) => StateTransition.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
    turnHistory: (json['turnHistory'] as List<dynamic>?)
            ?.map((t) => PlayerTurn.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
    scoreHistory: (json['scoreHistory'] as List<dynamic>?)
            ?.map((s) => Score.fromJson(s as Map<String, dynamic>))
            .toList() ??
        const [],
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

  static MatchCommand _commandFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'CreateMatchCommand':
        return const DummyMatchCommand('CreateMatchCommand');
      case 'JoinMatchCommand':
        return const DummyMatchCommand('JoinMatchCommand');
      case 'LeaveMatchCommand':
        return const DummyMatchCommand('LeaveMatchCommand');
      case 'StartMatchCommand':
        return const DummyMatchCommand('StartMatchCommand');
      case 'ChooseWordCommand':
        return const DummyMatchCommand('ChooseWordCommand');
      case 'SubmitGuessCommand':
        return const DummyMatchCommand('SubmitGuessCommand');
      case 'SkipTurnCommand':
        return const DummyMatchCommand('SkipTurnCommand');
      case 'EndRoundCommand':
        return const DummyMatchCommand('EndRoundCommand');
      case 'FinishMatchCommand':
        return const DummyMatchCommand('FinishMatchCommand');
      case 'CancelMatchCommand':
        return const DummyMatchCommand('CancelMatchCommand');
      case 'ReadyPlayerCommand':
        return const DummyMatchCommand('ReadyPlayerCommand');
      default:
        return const DummyMatchCommand('Unknown');
    }
  }

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

  /// Audit history of commands processed.
  final List<MatchCommand> commandHistory;

  /// Audit history of events generated.
  final List<MatchEvent> eventHistory;

  /// Audit history of state transitions.
  final List<StateTransition> transitionHistory;

  /// Audit history of turns played.
  final List<PlayerTurn> turnHistory;

  /// Audit history of scores awarded.
  final List<Score> scoreHistory;

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
    List<MatchCommand>? commandHistory,
    List<MatchEvent>? eventHistory,
    List<StateTransition>? transitionHistory,
    List<PlayerTurn>? turnHistory,
    List<Score>? scoreHistory,
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
    commandHistory: commandHistory ?? this.commandHistory,
    eventHistory: eventHistory ?? this.eventHistory,
    transitionHistory: transitionHistory ?? this.transitionHistory,
    turnHistory: turnHistory ?? this.turnHistory,
    scoreHistory: scoreHistory ?? this.scoreHistory,
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
    'commandHistory': commandHistory.map((c) => {'type': c.runtimeType.toString()}).toList(),
    'eventHistory': eventHistory.map((e) => e.toJson()).toList(),
    'transitionHistory': transitionHistory.map((t) => t.toJson()).toList(),
    'turnHistory': turnHistory.map((t) => t.toJson()).toList(),
    'scoreHistory': scoreHistory.map((s) => s.toJson()).toList(),
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
