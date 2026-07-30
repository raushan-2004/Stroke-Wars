import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

/// Immutable settings defining the setup of a Practice Mode session.
class PracticeConfiguration {
  /// Creates a [PracticeConfiguration] with default values.
  const PracticeConfiguration({
    this.rounds = 3,
    this.botCount = 2,
    this.difficulty = WordDifficulty.easy,
    this.categories = const [WordCategory.animals, WordCategory.food],
    this.drawTimeSecs = 60,
    this.scoreboardTimeSecs = 8,
    this.hintsEnabled = true,
    this.brushRestrictions = const [],
    this.replayEnabled = true,
    this.autosaveEnabled = true,
  });

  /// The number of rounds in this practice match.
  final int rounds;

  /// The number of simulated bot guessers.
  final int botCount;

  /// The difficulty filter for words loaded during practice.
  final WordDifficulty difficulty;

  /// Allowed word categories.
  final List<WordCategory> categories;

  /// Active drawing countdown timer duration in seconds.
  final int drawTimeSecs;

  /// Scoreboard display time between rounds.
  final int scoreboardTimeSecs;

  /// Whether characters are periodically revealed.
  final bool hintsEnabled;

  /// List of brush tip identifiers restricted in this configuration.
  final List<String> brushRestrictions;

  /// Whether to record stroke timelines for replays.
  final bool replayEnabled;

  /// Whether changes are automatically saved to disk.
  final bool autosaveEnabled;

  /// Creates a copy of this configuration with updated fields.
  PracticeConfiguration copyWith({
    int? rounds,
    int? botCount,
    WordDifficulty? difficulty,
    List<WordCategory>? categories,
    int? drawTimeSecs,
    int? scoreboardTimeSecs,
    bool? hintsEnabled,
    List<String>? brushRestrictions,
    bool? replayEnabled,
    bool? autosaveEnabled,
  }) {
    return PracticeConfiguration(
      rounds: rounds ?? this.rounds,
      botCount: botCount ?? this.botCount,
      difficulty: difficulty ?? this.difficulty,
      categories: categories ?? this.categories,
      drawTimeSecs: drawTimeSecs ?? this.drawTimeSecs,
      scoreboardTimeSecs: scoreboardTimeSecs ?? this.scoreboardTimeSecs,
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
      brushRestrictions: brushRestrictions ?? this.brushRestrictions,
      replayEnabled: replayEnabled ?? this.replayEnabled,
      autosaveEnabled: autosaveEnabled ?? this.autosaveEnabled,
    );
  }

  /// Converts this configuration to a JSON Map.
  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'botCount': botCount,
        'difficulty': difficulty.name,
        'categories': categories.map((c) => c.name).toList(),
        'drawTimeSecs': drawTimeSecs,
        'scoreboardTimeSecs': scoreboardTimeSecs,
        'hintsEnabled': hintsEnabled,
        'brushRestrictions': brushRestrictions,
        'replayEnabled': replayEnabled,
        'autosaveEnabled': autosaveEnabled,
      };

  /// Restores this configuration from a JSON Map.
  factory PracticeConfiguration.fromJson(Map<String, dynamic> json) =>
      PracticeConfiguration(
        rounds: json['rounds'] as int? ?? 3,
        botCount: json['botCount'] as int? ?? 2,
        difficulty: WordDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => WordDifficulty.easy,
        ),
        categories: (json['categories'] as List<dynamic>?)
                ?.map((c) => WordCategory.values.firstWhere(
                      (e) => e.name == c,
                      orElse: () => WordCategory.animals,
                    ))
                .toList() ??
            const [WordCategory.animals, WordCategory.food],
        drawTimeSecs: json['drawTimeSecs'] as int? ?? 60,
        scoreboardTimeSecs: json['scoreboardTimeSecs'] as int? ?? 8,
        hintsEnabled: json['hintsEnabled'] as bool? ?? true,
        brushRestrictions:
            List<String>.from(json['brushRestrictions'] as List? ?? const []),
        replayEnabled: json['replayEnabled'] as bool? ?? true,
        autosaveEnabled: json['autosaveEnabled'] as bool? ?? true,
      );
}
