import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';

/// Abstract interface for smoothing jagged lines using various curve interpolation algorithms.
abstract interface class StrokeSmoother {
  /// Smooths a list of points using configuration rules.
  List<StrokePoint> smooth(
    List<StrokePoint> points,
    DrawingEngineConfig config,
  );
}

/// A moving-average sliding-window filter smoothing coordinates.
class MovingAverageSmoother implements StrokeSmoother {
  /// Creates a [MovingAverageSmoother].
  const MovingAverageSmoother();

  @override
  List<StrokePoint> smooth(
    List<StrokePoint> points,
    DrawingEngineConfig config,
  ) {
    if (points.length < 3) return points;

    final windowSize = config.movingAverageWindowSize;
    final List<StrokePoint> smoothed = [];

    // Keep start anchor point exact
    smoothed.add(points.first);

    for (int i = 1; i < points.length - 1; i++) {
      double sumX = 0.0;
      double sumY = 0.0;
      double sumPressure = 0.0;
      double sumVelocity = 0.0;
      int count = 0;

      final start = (i - windowSize ~/ 2).clamp(0, points.length - 1);
      final end = (i + windowSize ~/ 2).clamp(0, points.length - 1);

      for (int w = start; w <= end; w++) {
        sumX += points[w].x;
        sumY += points[w].y;
        sumPressure += points[w].pressure;
        sumVelocity += points[w].velocity;
        count++;
      }

      smoothed.add(
        StrokePoint(
          x: sumX / count,
          y: sumY / count,
          timestamp: points[i].timestamp,
          pressure: sumPressure / count,
          velocity: sumVelocity / count,
        ),
      );
    }

    // Keep end anchor point exact
    smoothed.add(points.last);
    return smoothed;
  }
}

/// Interface hook for future Catmull-Rom spline calculations (placeholder).
class CatmullRomSmoother implements StrokeSmoother {
  /// Creates a [CatmullRomSmoother].
  const CatmullRomSmoother();

  @override
  List<StrokePoint> smooth(
    List<StrokePoint> points,
    DrawingEngineConfig config,
  ) => points;
}

/// Interface hook for future Bezier curve interpolation (placeholder).
class BezierSmoother implements StrokeSmoother {
  /// Creates a [BezierSmoother].
  const BezierSmoother();

  @override
  List<StrokePoint> smooth(
    List<StrokePoint> points,
    DrawingEngineConfig config,
  ) => points;
}

/// Interface hook for future Chaikin corner-cutting algorithm (placeholder).
class ChaikinSmoother implements StrokeSmoother {
  /// Creates a [ChaikinSmoother].
  const ChaikinSmoother();

  @override
  List<StrokePoint> smooth(
    List<StrokePoint> points,
    DrawingEngineConfig config,
  ) => points;
}
