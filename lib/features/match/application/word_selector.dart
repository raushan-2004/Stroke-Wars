import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';
import 'package:stroke_wars/features/match/domain/repositories/word_repository.dart';

/// Selects words from a [WordRepository] with difficulty and category balancing.
class WordSelector {
  /// Creates a [WordSelector].
  const WordSelector({required this.repository, required this.random});

  /// Word data source.
  final WordRepository repository;

  /// Randomness abstraction for deterministic testing.
  final RandomProvider random;

  /// Selects [count] words for the drawer to choose from.
  ///
  /// Strategy:
  /// 1. If [config] specifies custom word list, pull from that first.
  /// 2. Otherwise query the repository respecting [difficulty] and a random
  ///    category from [config.allowedCategories].
  /// 3. Shuffle the result before returning.
  Future<List<Word>> selectWordsForRound(MatchConfiguration config) async {
    final count = config.wordChoiceCount;

    // Custom word list takes priority
    if (config.customWordList.isNotEmpty) {
      return _buildCustomWords(config.customWordList, count);
    }

    final category = _pickCategory(config.allowedCategories);
    final words = await repository.getWords(
      difficulty: config.difficulty,
      category: category == WordCategory.random ? null : category,
      count: count * 2, // fetch extras in case of duplicates
    );

    final shuffled = random.shuffle(words);
    return shuffled.take(count).toList();
  }

  /// Selects a single word by ID (used during replay or host-override).
  Future<Word?> selectById(String wordId) async {
    final words = await repository.getWordsByIds([wordId]);
    return words.firstOrNull;
  }

  /// Selects a random category from the allowed list.
  WordCategory _pickCategory(List<WordCategory> allowed) {
    if (allowed.isEmpty) return WordCategory.random;
    final index = random.nextInt(allowed.length);
    return allowed[index];
  }

  /// Builds [Word] objects from the host's custom word strings.
  List<Word> _buildCustomWords(List<String> wordTexts, int count) {
    final words =
        wordTexts
            .where((t) => t.trim().isNotEmpty)
            .map(
              (t) => Word(
                id: 'custom_${t.toLowerCase().replaceAll(' ', '_')}',
                text: t.trim(),
                difficulty: WordDifficulty.medium,
                category: WordCategory.random,
              ),
            )
            .toList();
    final shuffled = random.shuffle(words);
    return shuffled.take(count).toList();
  }
}

extension _ListExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
