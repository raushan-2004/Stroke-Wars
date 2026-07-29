import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';

/// Processor calculating dynamic width and opacity levels depending on velocity and pressure.
class BrushProcessor {
  /// Creates a [BrushProcessor].
  const BrushProcessor();

  /// Computes line thickness based on active brush size, speed, and pressure.
  double calculateWidth(double baseWidth, StrokePoint point, BrushType type) {
    double factor = 1.0;

    // Apply pressure scaling effects (higher pressure = thicker stroke)
    factor *= point.pressure;

    // Apply speed-dampening velocity effects (higher speed = thinner stroke)
    const velocityLimit = 15.0;
    final velocityFactor =
        1.0 - (point.velocity / velocityLimit).clamp(0.0, 0.5);
    factor *= velocityFactor;

    // Clamp width to prevent line artifacts
    return (baseWidth * factor).clamp(1.0, 64.0);
  }

  /// Computes stroke opacity based on active opacity, speed, and pressure.
  double calculateOpacity(
    double baseOpacity,
    StrokePoint point,
    BrushType type,
  ) {
    double factor = 1.0;

    // Marker brushes reduce opacity when moving quickly
    if (type == BrushType.marker) {
      const velocityLimit = 20.0;
      final velocityFactor =
          1.0 - (point.velocity / velocityLimit).clamp(0.0, 0.6);
      factor *= velocityFactor;
    }

    return (baseOpacity * factor).clamp(0.1, 1.0);
  }
}
