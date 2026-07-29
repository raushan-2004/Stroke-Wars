import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';

/// Processes and normalizes input pressure parameters across mouse, touch, and stylus hardware.
class PressureProcessor {
  /// Creates a [PressureProcessor].
  const PressureProcessor();

  /// Normalizes pressure values between 0.0 and 1.0 using the engine configuration.
  double normalize(double rawPressure, DrawingEngineConfig config) {
    // If no pressure reported (e.g. standard touch/mouse reporting 0.0 or less), return default config value
    if (rawPressure <= 0.0) {
      return config.defaultPressure;
    }

    final normalized =
        (rawPressure - config.minPressure) /
        (config.maxPressure - config.minPressure);
    return normalized.clamp(0.0, 1.0) * config.pressureScaleFactor;
  }
}
