import 'dart:math';

/// Abstraction over random number generation.
///
/// Using [RandomProvider] instead of calling [Random] directly enables:
/// - Deterministic seeds in tests
/// - Deterministic replay playback
/// - Competitive match fairness (server-controlled seed, future)
abstract class RandomProvider {
  /// Returns a non-negative random integer less than [max].
  int nextInt(int max);

  /// Returns a random double in [0.0, 1.0).
  double nextDouble();

  /// Returns a new list with the items in [source] randomly shuffled.
  List<T> shuffle<T>(List<T> source);
}

/// Default [RandomProvider] backed by Dart's [Random].
///
/// Provide a [seed] for deterministic behaviour in tests or replay.
class DefaultRandomProvider implements RandomProvider {
  /// Creates a [DefaultRandomProvider].
  ///
  /// If [seed] is non-null the sequence will be deterministic.
  DefaultRandomProvider([int? seed])
    : _random = seed != null ? Random(seed) : Random.secure();

  final Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);

  @override
  double nextDouble() => _random.nextDouble();

  @override
  List<T> shuffle<T>(List<T> source) {
    final result = List<T>.from(source);
    for (var i = result.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }
}

/// A seeded [RandomProvider] that always produces the same sequence.
///
/// Useful for unit testing deterministic scenarios.
class SeededRandomProvider extends DefaultRandomProvider {
  /// Creates a [SeededRandomProvider] with the given [seed].
  SeededRandomProvider(int seed) : super(seed);
}
