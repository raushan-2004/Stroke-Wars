/// Difficulty classification for a [Word].
enum WordDifficulty {
  /// Common, short words suitable for beginners.
  easy,

  /// Standard vocabulary words.
  medium,

  /// Uncommon or compound words.
  hard,

  /// Rare, abstract, or domain-specific words.
  extreme,
}

/// Extension providing human-readable labels for [WordDifficulty].
extension WordDifficultyLabel on WordDifficulty {
  /// Returns the display name of this difficulty.
  String get label => switch (this) {
    WordDifficulty.easy => 'Easy',
    WordDifficulty.medium => 'Medium',
    WordDifficulty.hard => 'Hard',
    WordDifficulty.extreme => 'Extreme',
  };

  /// Returns the point multiplier applied to scores for this difficulty.
  double get pointMultiplier => switch (this) {
    WordDifficulty.easy => 1.0,
    WordDifficulty.medium => 1.25,
    WordDifficulty.hard => 1.5,
    WordDifficulty.extreme => 2.0,
  };
}
