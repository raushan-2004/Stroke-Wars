import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

/// Abstract repository interface for word retrieval.
///
/// Difficulty and category are completely independent query parameters.
/// Implementations may serve from local lists, a server, or localised sources.
abstract interface class WordRepository {
  /// Returns a list of [Word]s matching the given filters.
  ///
  /// [difficulty] and [category] are optional and may be combined.
  /// [count] specifies the number of words to return.
  Future<List<Word>> getWords({
    WordDifficulty? difficulty,
    WordCategory? category,
    int count = 3,
  });

  /// Returns words matching a list of specific IDs.
  Future<List<Word>> getWordsByIds(List<String> ids);

  /// Returns all available categories in this repository.
  Future<List<WordCategory>> getAvailableCategories();

  /// Returns all available difficulties in this repository.
  Future<List<WordDifficulty>> getAvailableDifficulties();
}
