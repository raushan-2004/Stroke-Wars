import 'package:stroke_wars/features/match/domain/models/round_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

/// Top-level configuration for an entire [Match].
class MatchConfiguration {
  /// Creates an immutable [MatchConfiguration] with sensible defaults.
  const MatchConfiguration({
    this.maxPlayers = 8,
    this.minPlayers = 2,
    this.totalRounds = 3,
    this.drawTimeSecs = 80,
    this.guessTimeSecs = 80,
    this.preparationTimeSecs = 3,
    this.scoreboardTimeSecs = 5,
    this.difficulty = WordDifficulty.medium,
    this.allowedCategories = WordCategory.values,
    this.wordChoiceCount = 3,
    this.isPrivate = false,
    this.customWordList = const [],
    this.isRanked = false,
    this.enableHints = true,
    this.hintRevealCount = 2,
  });

  /// Creates a [MatchConfiguration] from a JSON map.
  factory MatchConfiguration.fromJson(Map<String, dynamic> json) =>
      MatchConfiguration(
        maxPlayers: json['maxPlayers'] as int? ?? 8,
        minPlayers: json['minPlayers'] as int? ?? 2,
        totalRounds: json['totalRounds'] as int? ?? 3,
        drawTimeSecs: json['drawTimeSecs'] as int? ?? 80,
        guessTimeSecs: json['guessTimeSecs'] as int? ?? 80,
        preparationTimeSecs: json['preparationTimeSecs'] as int? ?? 3,
        scoreboardTimeSecs: json['scoreboardTimeSecs'] as int? ?? 5,
        difficulty: WordDifficulty.values.firstWhere(
          (d) => d.name == json['difficulty'],
          orElse: () => WordDifficulty.medium,
        ),
        allowedCategories:
            (json['allowedCategories'] as List<dynamic>?)
                ?.map((c) => WordCategory.values.firstWhere((v) => v.name == c))
                .toList() ??
            WordCategory.values,
        wordChoiceCount: json['wordChoiceCount'] as int? ?? 3,
        isPrivate: json['isPrivate'] as bool? ?? false,
        customWordList:
            (json['customWordList'] as List<dynamic>?)?.cast<String>() ??
            const [],
        isRanked: json['isRanked'] as bool? ?? false,
        enableHints: json['enableHints'] as bool? ?? true,
        hintRevealCount: json['hintRevealCount'] as int? ?? 2,
      );

  /// Maximum number of players allowed in the match.
  final int maxPlayers;

  /// Minimum number of players required to start.
  final int minPlayers;

  /// Total number of rounds to play.
  final int totalRounds;

  /// Seconds per drawing phase.
  final int drawTimeSecs;

  /// Seconds per guessing phase.
  final int guessTimeSecs;

  /// Preparation countdown seconds before each round.
  final int preparationTimeSecs;

  /// Seconds to display the scoreboard between rounds.
  final int scoreboardTimeSecs;

  /// Default word difficulty level.
  final WordDifficulty difficulty;

  /// Categories from which words can be drawn.
  final List<WordCategory> allowedCategories;

  /// How many words are offered to the drawer per round.
  final int wordChoiceCount;

  /// Whether the room requires an invite code to join.
  final bool isPrivate;

  /// Optional host-provided word list (overrides repository words).
  final List<String> customWordList;

  /// Whether this match counts toward ranked statistics (future).
  final bool isRanked;

  /// Whether progressive letter hints are revealed.
  final bool enableHints;

  /// Number of letters revealed as hints per round.
  final int hintRevealCount;

  /// Derives a [RoundConfiguration] from this match configuration.
  RoundConfiguration get roundConfiguration => RoundConfiguration(
    drawTimeSecs: drawTimeSecs,
    guessTimeSecs: guessTimeSecs,
    wordChoiceCount: wordChoiceCount,
    revealHints: enableHints,
    hintCount: hintRevealCount,
  );

  /// Returns a copy with the specified fields replaced.
  MatchConfiguration copyWith({
    int? maxPlayers,
    int? minPlayers,
    int? totalRounds,
    int? drawTimeSecs,
    int? guessTimeSecs,
    int? preparationTimeSecs,
    int? scoreboardTimeSecs,
    WordDifficulty? difficulty,
    List<WordCategory>? allowedCategories,
    int? wordChoiceCount,
    bool? isPrivate,
    List<String>? customWordList,
    bool? isRanked,
    bool? enableHints,
    int? hintRevealCount,
  }) => MatchConfiguration(
    maxPlayers: maxPlayers ?? this.maxPlayers,
    minPlayers: minPlayers ?? this.minPlayers,
    totalRounds: totalRounds ?? this.totalRounds,
    drawTimeSecs: drawTimeSecs ?? this.drawTimeSecs,
    guessTimeSecs: guessTimeSecs ?? this.guessTimeSecs,
    preparationTimeSecs: preparationTimeSecs ?? this.preparationTimeSecs,
    scoreboardTimeSecs: scoreboardTimeSecs ?? this.scoreboardTimeSecs,
    difficulty: difficulty ?? this.difficulty,
    allowedCategories: allowedCategories ?? this.allowedCategories,
    wordChoiceCount: wordChoiceCount ?? this.wordChoiceCount,
    isPrivate: isPrivate ?? this.isPrivate,
    customWordList: customWordList ?? this.customWordList,
    isRanked: isRanked ?? this.isRanked,
    enableHints: enableHints ?? this.enableHints,
    hintRevealCount: hintRevealCount ?? this.hintRevealCount,
  );

  /// Converts this [MatchConfiguration] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'maxPlayers': maxPlayers,
    'minPlayers': minPlayers,
    'totalRounds': totalRounds,
    'drawTimeSecs': drawTimeSecs,
    'guessTimeSecs': guessTimeSecs,
    'preparationTimeSecs': preparationTimeSecs,
    'scoreboardTimeSecs': scoreboardTimeSecs,
    'difficulty': difficulty.name,
    'allowedCategories': allowedCategories.map((c) => c.name).toList(),
    'wordChoiceCount': wordChoiceCount,
    'isPrivate': isPrivate,
    'customWordList': customWordList,
    'isRanked': isRanked,
    'enableHints': enableHints,
    'hintRevealCount': hintRevealCount,
  };

  @override
  bool operator ==(Object other) =>
      other is MatchConfiguration &&
      other.maxPlayers == maxPlayers &&
      other.totalRounds == totalRounds &&
      other.drawTimeSecs == drawTimeSecs &&
      other.difficulty == difficulty &&
      other.isPrivate == isPrivate;

  @override
  int get hashCode =>
      Object.hash(maxPlayers, totalRounds, drawTimeSecs, difficulty, isPrivate);
}
