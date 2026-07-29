import 'package:stroke_wars/features/canvas/domain/models/input/input_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';

/// Strategy pattern interface responsible for pointer preprocessing depending on device types.
abstract interface class InputStrategy {
  /// Preprocesses raw input events (e.g. pressure overrides, dampening) before they enter the pipeline.
  InputEvent preprocess(InputEvent event, DrawingEngineConfig config);
}

/// Preprocessor handling finger contacts.
class TouchStrategy implements InputStrategy {
  /// Creates a [TouchStrategy].
  const TouchStrategy();

  @override
  InputEvent preprocess(InputEvent event, DrawingEngineConfig config) {
    // Standard capacitive touch defaults to default config pressure
    return event;
  }
}

/// Preprocessor handling active stylus digitizer signals.
class StylusStrategy implements InputStrategy {
  /// Creates a [StylusStrategy].
  const StylusStrategy();

  @override
  InputEvent preprocess(InputEvent event, DrawingEngineConfig config) {
    // Preserves native hardware pressure inputs
    return event;
  }
}

/// Preprocessor handling standard desktop mouse devices.
class MouseStrategy implements InputStrategy {
  /// Creates a [MouseStrategy].
  const MouseStrategy();

  @override
  InputEvent preprocess(InputEvent event, DrawingEngineConfig config) {
    // Mouse devices apply config default pressure levels
    return event;
  }
}

/// Preprocessor handling synthetic playback inputs.
class ReplayStrategy implements InputStrategy {
  /// Creates a [ReplayStrategy].
  const ReplayStrategy();

  @override
  InputEvent preprocess(InputEvent event, DrawingEngineConfig config) {
    return event;
  }
}
