import 'package:stroke_wars/features/canvas/domain/models/input/input_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';

/// Filters raw pointer noise, duplicate coordinates, and micro tremors.
class InputFilter {
  /// Creates an [InputFilter].
  const InputFilter();

  /// Evaluates whether an input event is valid or represents noise to be suppressed.
  bool shouldProcess(
    InputEvent event,
    InputEvent? lastEvent,
    DrawingEngineConfig config,
  ) {
    if (lastEvent == null) return true;

    // Suppress coordinates that represent duplicates within a tight tolerance
    final dx = (event.localPosition.dx - lastEvent.localPosition.dx).abs();
    final dy = (event.localPosition.dy - lastEvent.localPosition.dy).abs();
    if (dx <= config.duplicateTolerance && dy <= config.duplicateTolerance) {
      return false;
    }

    // Filter out extremely tiny jitter movements below a micro threshold
    if (event is PointerMove) {
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared < 0.2) {
        return false;
      }
    }

    return true;
  }
}
