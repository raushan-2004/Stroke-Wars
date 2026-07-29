import 'dart:async';

/// A utility that limits the rate at which a function is called.
///
/// Useful for search inputs, resize listeners, and other high-frequency events.
final class Debouncer {
  /// Creates a [Debouncer] with the specified [delay].
  Debouncer({required this.delay});

  /// The delay duration before the callback is invoked.
  final Duration delay;
  Timer? _timer;

  /// Schedules [action] to be called after [delay].
  /// Resets the timer if called again before [delay] elapses.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether a pending action is scheduled.
  bool get isPending => _timer?.isActive ?? false;

  /// Disposes the debouncer, cancelling any pending action.
  void dispose() => cancel();
}
