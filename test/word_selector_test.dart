import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

void main() {
  // ────────────────────────────────────────────
  // RandomProvider
  // ────────────────────────────────────────────
  group('RandomProvider', () {
    test('SeededRandomProvider produces deterministic sequence', () {
      final r1 = SeededRandomProvider(42);
      final r2 = SeededRandomProvider(42);
      final seq1 = List.generate(5, (_) => r1.nextInt(100));
      final seq2 = List.generate(5, (_) => r2.nextInt(100));
      expect(seq1, equals(seq2));
    });

    test('Different seeds produce different sequences', () {
      final r1 = SeededRandomProvider(1);
      final r2 = SeededRandomProvider(99);
      final seq1 = List.generate(5, (_) => r1.nextInt(1000));
      final seq2 = List.generate(5, (_) => r2.nextInt(1000));
      expect(seq1, isNot(equals(seq2)));
    });

    test('nextDouble returns value in [0.0, 1.0)', () {
      final r = SeededRandomProvider(7);
      for (var i = 0; i < 20; i++) {
        final v = r.nextDouble();
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThan(1.0));
      }
    });

    test('shuffle returns all original elements', () {
      final r = SeededRandomProvider(123);
      final input = [1, 2, 3, 4, 5, 6, 7];
      final shuffled = r.shuffle(input);
      expect(shuffled.toSet(), equals(input.toSet()));
      expect(shuffled.length, input.length);
    });

    test('shuffle does not mutate the original list', () {
      final r = SeededRandomProvider(456);
      final original = [1, 2, 3, 4, 5];
      final copy = List<int>.from(original);
      r.shuffle(original);
      expect(original, equals(copy));
    });

    test('SeededRandomProvider shuffle is deterministic', () {
      final input = [10, 20, 30, 40, 50];
      final r1 = SeededRandomProvider(9);
      final r2 = SeededRandomProvider(9);
      expect(r1.shuffle(input), equals(r2.shuffle(input)));
    });
  });

  // ────────────────────────────────────────────
  // MatchValidator
  // ────────────────────────────────────────────
  group('MatchValidator', () {
    const validator = MatchValidator();

    group('validateTransition()', () {
      test('created → waiting is valid', () {
        final result = validator.validateTransition(
          const MatchCreatedState(),
          const MatchWaitingState(),
        );
        expect(result.isValid, isTrue);
      });

      test('waiting → drawing is invalid (must go through starting)', () {
        final result = validator.validateTransition(
          const MatchWaitingState(),
          const DrawingState(),
        );
        expect(result.isValid, isFalse);
        expect(result.reason, isNotEmpty);
      });

      test('finished state has no valid transitions', () {
        final result = validator.validateTransition(
          const MatchFinishedState(),
          const MatchWaitingState(),
        );
        expect(result.isValid, isFalse);
      });

      test('any active state can transition to cancelled', () {
        final activeStates = [
          const MatchWaitingState(),
          const MatchStartingState(),
          const DrawingState(),
          const GuessingState(),
        ];
        for (final state in activeStates) {
          final result = validator.validateTransition(
            state,
            const MatchCancelledState(),
          );
          expect(
            result.isValid,
            isTrue,
            reason: 'State ${state.label} should allow cancel',
          );
        }
      });

      test('scoreboard → wordSelection is valid (next round)', () {
        final result = validator.validateTransition(
          const ScoreboardState(),
          const WordSelectionState(),
        );
        expect(result.isValid, isTrue);
      });

      test('scoreboard → matchFinished is valid', () {
        final result = validator.validateTransition(
          const ScoreboardState(),
          const MatchFinishedState(),
        );
        expect(result.isValid, isTrue);
      });
    });

    group('validateConfiguration()', () {
      test('default configuration passes validation', () {
        const config = MatchConfiguration();
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isTrue);
      });

      test('maxPlayers < 2 fails validation', () {
        const config = MatchConfiguration(maxPlayers: 1);
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isFalse);
      });

      test('totalRounds = 0 fails validation', () {
        const config = MatchConfiguration(totalRounds: 0);
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isFalse);
      });

      test('drawTimeSecs < 10 fails validation', () {
        const config = MatchConfiguration(drawTimeSecs: 5);
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isFalse);
      });

      test('wordChoiceCount > 5 fails validation', () {
        const config = MatchConfiguration(wordChoiceCount: 6);
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isFalse);
      });

      test('empty allowedCategories fails validation', () {
        const config = MatchConfiguration(allowedCategories: []);
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isFalse);
      });

      test('minPlayers > maxPlayers fails validation', () {
        const config = MatchConfiguration(minPlayers: 8, maxPlayers: 4);
        final result = validator.validateConfiguration(config);
        expect(result.isValid, isFalse);
      });
    });

    group('validatePlayerJoin()', () {
      test('joining when space is available passes', () {
        const config = MatchConfiguration(maxPlayers: 4);
        final players = [
          const PlayerSlot(
            slotId: 's1',
            playerId: 'p1',
            displayName: 'Alice',
            role: PlayerRole.host,
          ),
        ];
        final result = validator.validatePlayerJoin(players, config);
        expect(result.isValid, isTrue);
      });

      test('joining when match is full fails', () {
        const config = MatchConfiguration(maxPlayers: 2);
        final players = [
          const PlayerSlot(
            slotId: 's1',
            playerId: 'p1',
            displayName: 'Alice',
            role: PlayerRole.host,
          ),
          const PlayerSlot(
            slotId: 's2',
            playerId: 'p2',
            displayName: 'Bob',
            role: PlayerRole.guesser,
          ),
        ];
        final result = validator.validatePlayerJoin(players, config);
        expect(result.isValid, isFalse);
      });
    });

    group('validateReadyToStart()', () {
      test('enough players passes', () {
        const config = MatchConfiguration(minPlayers: 2);
        final players = [
          const PlayerSlot(
            slotId: 's1',
            playerId: 'p1',
            displayName: 'Alice',
            role: PlayerRole.host,
          ),
          const PlayerSlot(
            slotId: 's2',
            playerId: 'p2',
            displayName: 'Bob',
            role: PlayerRole.guesser,
          ),
        ];
        final result = validator.validateReadyToStart(players, config);
        expect(result.isValid, isTrue);
      });

      test('not enough players fails', () {
        const config = MatchConfiguration(minPlayers: 3);
        final players = [
          const PlayerSlot(
            slotId: 's1',
            playerId: 'p1',
            displayName: 'Alice',
            role: PlayerRole.host,
          ),
        ];
        final result = validator.validateReadyToStart(players, config);
        expect(result.isValid, isFalse);
      });
    });

    group('validateGuessTime()', () {
      test('valid guess time passes', () {
        final result = validator.validateGuessTime(30000, 80);
        expect(result.isValid, isTrue);
      });

      test('negative guess time fails', () {
        final result = validator.validateGuessTime(-1, 80);
        expect(result.isValid, isFalse);
      });

      test('guess time exceeding max duration fails', () {
        final result = validator.validateGuessTime(90000, 80); // 90s > 80s
        expect(result.isValid, isFalse);
      });
    });
  });

  // ────────────────────────────────────────────
  // WordSelector
  // ────────────────────────────────────────────
  group('WordSelector', () {
    final repo = DefaultWordList();

    test('selectWordsForRound returns correct count', () async {
      const config = MatchConfiguration(wordChoiceCount: 3);
      final selector = WordSelector(
        repository: repo,
        random: SeededRandomProvider(1),
      );
      final words = await selector.selectWordsForRound(config);
      expect(words.length, lessThanOrEqualTo(3));
      expect(words, isNotEmpty);
    });

    test('selectWordsForRound respects difficulty filter', () async {
      const config = MatchConfiguration(
        difficulty: WordDifficulty.easy,
        wordChoiceCount: 5,
        allowedCategories: WordCategory.values,
      );
      final selector = WordSelector(
        repository: repo,
        random: SeededRandomProvider(2),
      );
      final words = await selector.selectWordsForRound(config);
      for (final word in words) {
        expect(word.difficulty, WordDifficulty.easy);
      }
    });

    test('custom word list is used when provided', () async {
      const config = MatchConfiguration(
        wordChoiceCount: 2,
        customWordList: ['Banana', 'Spacecraft', 'Cello'],
      );
      final selector = WordSelector(
        repository: repo,
        random: SeededRandomProvider(3),
      );
      final words = await selector.selectWordsForRound(config);
      expect(words.length, 2);
      final texts = words.map((w) => w.text).toSet();
      expect(
        texts.every((t) => ['Banana', 'Spacecraft', 'Cello'].contains(t)),
        isTrue,
      );
    });

    test('seeded selector produces deterministic word order', () async {
      const config = MatchConfiguration(wordChoiceCount: 3);
      final selector1 = WordSelector(
        repository: repo,
        random: SeededRandomProvider(42),
      );
      final selector2 = WordSelector(
        repository: repo,
        random: SeededRandomProvider(42),
      );
      final words1 = await selector1.selectWordsForRound(config);
      final words2 = await selector2.selectWordsForRound(config);
      expect(
        words1.map((w) => w.id).toList(),
        equals(words2.map((w) => w.id).toList()),
      );
    });

    test('DefaultWordList returns words by category', () async {
      final words = await repo.getWords(
        category: WordCategory.sports,
        count: 5,
      );
      for (final word in words) {
        expect(word.category, WordCategory.sports);
      }
    });

    test('DefaultWordList returns words by difficulty', () async {
      final words = await repo.getWords(
        difficulty: WordDifficulty.hard,
        count: 5,
      );
      for (final word in words) {
        expect(word.difficulty, WordDifficulty.hard);
      }
    });

    test('DefaultWordList getWordsByIds returns matching words', () async {
      final words = await repo.getWordsByIds(['a_easy_01', 'f_easy_01']);
      expect(words.length, 2);
      final ids = words.map((w) => w.id).toSet();
      expect(ids, containsAll(['a_easy_01', 'f_easy_01']));
    });

    test(
      'DefaultWordList getAvailableCategories returns all categories',
      () async {
        final cats = await repo.getAvailableCategories();
        expect(cats.length, WordCategory.values.length);
      },
    );
  });

  // ────────────────────────────────────────────
  // ValidationResult
  // ────────────────────────────────────────────
  group('ValidationResult', () {
    test('ValidationResult.ok() is valid with no reason', () {
      const result = ValidationResult.ok();
      expect(result.isValid, isTrue);
      expect(result.reason, isNull);
    });

    test('ValidationResult.fail() is invalid with reason', () {
      const result = ValidationResult.fail('test reason');
      expect(result.isValid, isFalse);
      expect(result.reason, 'test reason');
    });
  });
}
