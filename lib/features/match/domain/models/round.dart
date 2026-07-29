import 'package:stroke_wars/features/match/domain/models/guess.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';
import 'package:stroke_wars/features/match/domain/models/round_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/score.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';

/// Immutable model representing a single drawing round within a [Match].
class Round {
  /// Creates an immutable [Round].
  const Round({
    required this.id,
    required this.matchId,
    required this.roundNumber,
    required this.state,
    required this.drawerSlotId,
    required this.configuration,
    this.word,
    this.wordOptions = const [],
    this.guesses = const [],
    this.scores = const [],
    this.playerTurn,
    this.timerState,
    this.startedAt,
    this.finishedAt,
  });

  /// Creates a [Round] from a JSON map.
  factory Round.fromJson(Map<String, dynamic> json) => Round(
    id: RoundId(json['id'] as String),
    matchId: MatchId(json['matchId'] as String),
    roundNumber: json['roundNumber'] as int,
    state: _stateFromJson(json['state'] as String),
    drawerSlotId: json['drawerSlotId'] as String,
    configuration: RoundConfiguration.fromJson(
      json['configuration'] as Map<String, dynamic>,
    ),
    word:
        json['word'] != null
            ? Word.fromJson(json['word'] as Map<String, dynamic>)
            : null,
    wordOptions:
        (json['wordOptions'] as List<dynamic>?)
            ?.map((w) => Word.fromJson(w as Map<String, dynamic>))
            .toList() ??
        const [],
    guesses:
        (json['guesses'] as List<dynamic>?)
            ?.map((g) => Guess.fromJson(g as Map<String, dynamic>))
            .toList() ??
        const [],
    scores:
        (json['scores'] as List<dynamic>?)
            ?.map((s) => Score.fromJson(s as Map<String, dynamic>))
            .toList() ??
        const [],
    playerTurn:
        json['playerTurn'] != null
            ? PlayerTurn.fromJson(json['playerTurn'] as Map<String, dynamic>)
            : null,
    timerState:
        json['timerState'] != null
            ? TimerState.fromJson(json['timerState'] as Map<String, dynamic>)
            : null,
    startedAt:
        json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
    finishedAt:
        json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'] as String)
            : null,
  );

  static RoundState _stateFromJson(String name) => switch (name) {
    'idle' => const RoundIdleState(),
    'preparing' => const RoundPreparingState(),
    'active' => const RoundActiveState(),
    'finished' => const RoundFinishedRoundState(),
    'cancelled' => const RoundCancelledState(),
    _ => const RoundIdleState(),
  };

  static String _stateToJson(RoundState state) => switch (state) {
    RoundIdleState() => 'idle',
    RoundPreparingState() => 'preparing',
    RoundActiveState() => 'active',
    RoundFinishedRoundState() => 'finished',
    RoundCancelledState() => 'cancelled',
  };

  /// Unique identifier for this round.
  final RoundId id;

  /// Parent match identifier.
  final MatchId matchId;

  /// 1-based round number within the match.
  final int roundNumber;

  /// Current lifecycle state.
  final RoundState state;

  /// Slot ID of the player currently drawing.
  final String drawerSlotId;

  /// Configuration applied to this round.
  final RoundConfiguration configuration;

  /// The chosen word for this round. Null before the drawer selects.
  final Word? word;

  /// Words offered to the drawer to choose from.
  final List<Word> wordOptions;

  /// All guess attempts submitted during this round.
  final List<Guess> guesses;

  /// Scores awarded at the end of this round.
  final List<Score> scores;

  /// Historical turn record for this round.
  final PlayerTurn? playerTurn;

  /// Current timer snapshot.
  final TimerState? timerState;

  /// When drawing began.
  final DateTime? startedAt;

  /// When the round was resolved.
  final DateTime? finishedAt;

  /// Number of players who guessed correctly this round.
  int get correctGuessCount =>
      guesses.where((g) => g.result.awardsPoints).length;

  /// Returns a copy with the specified fields replaced.
  Round copyWith({
    RoundId? id,
    MatchId? matchId,
    int? roundNumber,
    RoundState? state,
    String? drawerSlotId,
    RoundConfiguration? configuration,
    Word? word,
    List<Word>? wordOptions,
    List<Guess>? guesses,
    List<Score>? scores,
    PlayerTurn? playerTurn,
    TimerState? timerState,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) => Round(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    roundNumber: roundNumber ?? this.roundNumber,
    state: state ?? this.state,
    drawerSlotId: drawerSlotId ?? this.drawerSlotId,
    configuration: configuration ?? this.configuration,
    word: word ?? this.word,
    wordOptions: wordOptions ?? this.wordOptions,
    guesses: guesses ?? this.guesses,
    scores: scores ?? this.scores,
    playerTurn: playerTurn ?? this.playerTurn,
    timerState: timerState ?? this.timerState,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
  );

  /// Converts this [Round] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'id': id.value,
    'matchId': matchId.value,
    'roundNumber': roundNumber,
    'state': _stateToJson(state),
    'drawerSlotId': drawerSlotId,
    'configuration': configuration.toJson(),
    'word': word?.toJson(),
    'wordOptions': wordOptions.map((w) => w.toJson()).toList(),
    'guesses': guesses.map((g) => g.toJson()).toList(),
    'scores': scores.map((s) => s.toJson()).toList(),
    'playerTurn': playerTurn?.toJson(),
    'timerState': timerState?.toJson(),
    'startedAt': startedAt?.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) => other is Round && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Round(#$roundNumber, drawer=$drawerSlotId, state=${state.label})';
}
