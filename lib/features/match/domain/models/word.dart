import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

/// An immutable word used during a drawing round.
class Word {
  /// Creates an immutable [Word].
  const Word({
    required this.id,
    required this.text,
    required this.difficulty,
    required this.category,
    this.hints = const [],
  });

  /// Creates a [Word] from a JSON map.
  factory Word.fromJson(Map<String, dynamic> json) => Word(
    id: json['id'] as String,
    text: json['text'] as String,
    difficulty: WordDifficulty.values.firstWhere(
      (d) => d.name == json['difficulty'],
    ),
    category: WordCategory.values.firstWhere((c) => c.name == json['category']),
    hints: (json['hints'] as List<dynamic>).cast<String>(),
  );

  /// Unique identifier for this word.
  final String id;

  /// The word or phrase to be drawn.
  final String text;

  /// Difficulty classification.
  final WordDifficulty difficulty;

  /// Thematic category.
  final WordCategory category;

  /// Optional progressive hints revealed during the round.
  final List<String> hints;

  /// Returns a masked version of the text (e.g. "_ _ _ _") for display.
  String get masked =>
      text.split('').map((c) => c == ' ' ? ' ' : '_').join(' ');

  /// Returns a partial reveal of the word showing [revealCount] random letters.
  String partialReveal(int revealCount) {
    if (revealCount <= 0) return masked;
    final chars = text.split('');
    final indices = <int>[];
    for (var i = 0; i < chars.length; i++) {
      if (chars[i] != ' ') indices.add(i);
    }
    indices.shuffle();
    final revealed = Set<int>.from(indices.take(revealCount));
    return chars
        .asMap()
        .entries
        .map((e) {
          if (e.value == ' ') return ' ';
          return revealed.contains(e.key) ? e.value : '_';
        })
        .join(' ');
  }

  /// Returns a copy of this [Word] with the specified fields replaced.
  Word copyWith({
    String? id,
    String? text,
    WordDifficulty? difficulty,
    WordCategory? category,
    List<String>? hints,
  }) => Word(
    id: id ?? this.id,
    text: text ?? this.text,
    difficulty: difficulty ?? this.difficulty,
    category: category ?? this.category,
    hints: hints ?? this.hints,
  );

  /// Converts this [Word] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'difficulty': difficulty.name,
    'category': category.name,
    'hints': hints,
  };

  @override
  bool operator ==(Object other) => other is Word && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Word($text, ${difficulty.name}, ${category.name})';
}
