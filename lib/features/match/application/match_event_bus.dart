import 'dart:async';

import 'package:stroke_wars/features/match/domain/events/match_event.dart';

/// A stream-based event bus that fans out [MatchEvent]s to all subscribers.
///
/// Mirrors the [DrawingEventBus] pattern from Stage 4B.
///
/// Architecture:
/// ```
/// MatchController
///     ↓ publish()
/// MatchEventBus
///     ↓ stream
/// Subscribers (Replay / Networking / Analytics / Achievements)
/// ```
///
/// Subscribers never communicate directly with [MatchController].
class MatchEventBus {
  /// Creates a [MatchEventBus].
  MatchEventBus() : _controller = StreamController<MatchEvent>.broadcast();

  final StreamController<MatchEvent> _controller;
  bool _disposed = false;

  /// Stream of all published [MatchEvent]s.
  ///
  /// Subscribe to this stream to receive live match events.
  Stream<MatchEvent> get stream => _controller.stream;

  /// Returns a filtered stream containing only events of type [T].
  Stream<T> on<T extends MatchEvent>() =>
      stream.where((e) => e is T).cast<T>();

  /// Publishes a [MatchEvent] to all subscribers.
  ///
  /// No-ops after [dispose] is called.
  void publish(MatchEvent event) {
    if (_disposed) return;
    _controller.add(event);
  }

  /// Closes the stream and releases resources.
  void dispose() {
    _disposed = true;
    _controller.close();
  }
}

/// Dispatches [MatchEvent]s to a [MatchEventBus].
///
/// [MatchController] holds a reference to [MatchEventDispatcher] and
/// calls [dispatch] after each successful state mutation.
class MatchEventDispatcher {
  /// Creates a [MatchEventDispatcher] connected to the given [bus].
  const MatchEventDispatcher({required this.bus});

  /// The event bus receiving dispatched events.
  final MatchEventBus bus;

  /// Dispatches a single [MatchEvent] to the bus.
  void dispatch(MatchEvent event) => bus.publish(event);

  /// Dispatches a list of [MatchEvent]s in order.
  void dispatchAll(List<MatchEvent> events) {
    for (final event in events) {
      bus.publish(event);
    }
  }
}
