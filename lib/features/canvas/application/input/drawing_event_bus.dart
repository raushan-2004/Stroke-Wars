import 'dart:async';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';

/// Central decoupled pub-sub message event bus for broadcasting drawing stream actions.
class DrawingEventBus {
  final StreamController<DrawingEvent> _controller =
      StreamController<DrawingEvent>.broadcast();

  /// Gets the stream of all published drawing events.
  Stream<DrawingEvent> get stream => _controller.stream;

  /// Publishes a [DrawingEvent] to all active stream subscribers.
  void publish(DrawingEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  /// Closes the event stream controller.
  void dispose() {
    _controller.close();
  }
}
