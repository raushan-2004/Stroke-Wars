import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';

part 'drawing_event_dispatcher.g.dart';

/// Exposes the centralized Event Bus.
@riverpod
DrawingEventBus drawingEventBus(DrawingEventBusRef ref) {
  final bus = DrawingEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
}

/// Dispatches canvas engine events through the DrawingEventBus.
class DrawingEventDispatcher {
  /// Creates a [DrawingEventDispatcher].
  DrawingEventDispatcher({required this.eventBus});

  /// The active event bus used for publishing.
  final DrawingEventBus eventBus;

  /// Dispatches the event onto the event bus stream.
  void dispatch(DrawingEvent event) {
    eventBus.publish(event);
  }
}

/// Provider for accessing the [DrawingEventDispatcher] singleton.
@riverpod
DrawingEventDispatcher drawingEventDispatcher(DrawingEventDispatcherRef ref) {
  final bus = ref.watch(drawingEventBusProvider);
  return DrawingEventDispatcher(eventBus: bus);
}
