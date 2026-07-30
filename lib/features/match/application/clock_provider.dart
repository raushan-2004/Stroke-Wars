/// Abstract contract providing the current time.
///
/// Decoupling the game engine from `DateTime.now()` enables 100% deterministic
/// gameplay testing, time-travel debugging, and accurate replay systems.
abstract class ClockProvider {
  const ClockProvider();

  /// Returns the current date and time.
  DateTime get now;
}

/// Production implementation of [ClockProvider] returning the real system clock time.
class SystemClock extends ClockProvider {
  const SystemClock();

  @override
  DateTime get now => DateTime.now();
}

/// Test/Mock implementation of [ClockProvider] allowing manual manipulation of time.
class TestClock extends ClockProvider {
  TestClock(DateTime initialTime) : _now = initialTime;

  DateTime _now;

  @override
  DateTime get now => _now;

  /// Sets the current time to a specific value.
  set now(DateTime value) => _now = value;

  /// Advances the clock time by the specified [duration].
  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
