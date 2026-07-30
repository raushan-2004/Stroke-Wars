/// Generator for monotonically increasing sequence numbers.
///
/// Ensures deterministic ordering of match events, serving as a primary
/// key index for replays and distributed state synchronization.
class SequenceGenerator {
  SequenceGenerator({int initialValue = 0}) : _current = initialValue;

  int _current;

  /// Returns the current sequence number.
  int get current => _current;

  /// Sets the current sequence number (primarily for replay/restore purposes).
  set current(int value) => _current = value;

  /// Generates the next sequence number in sequence.
  int next() => ++_current;

  /// Resets the generator back to zero.
  void reset() {
    _current = 0;
  }
}
