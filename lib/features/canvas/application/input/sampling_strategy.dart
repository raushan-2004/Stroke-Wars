import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';

/// Abstract interface for point sampling strategies to prevent recording redundant coordinates.
abstract class SamplingStrategy {
  /// Base constructor.
  const SamplingStrategy();

  /// Evaluates whether a new point coordinates should be recorded compared to the last recorded point.
  bool shouldSample(
    StrokePoint newPoint,
    StrokePoint? lastPoint,
    DrawingEngineConfig config,
  );
}

/// Evaluates sampling based on physical distance thresholds.
class DistanceSamplingStrategy extends SamplingStrategy {
  /// Creates a [DistanceSamplingStrategy].
  const DistanceSamplingStrategy();

  @override
  bool shouldSample(
    StrokePoint newPoint,
    StrokePoint? lastPoint,
    DrawingEngineConfig config,
  ) {
    if (lastPoint == null) return true;
    final dx = newPoint.x - lastPoint.x;
    final dy = newPoint.y - lastPoint.y;
    final distSq = dx * dx + dy * dy;
    return distSq >= (config.distanceThreshold * config.distanceThreshold);
  }
}

/// Evaluates sampling based on elapsed milliseconds.
class TimeSamplingStrategy extends SamplingStrategy {
  /// Creates a [TimeSamplingStrategy].
  const TimeSamplingStrategy();

  @override
  bool shouldSample(
    StrokePoint newPoint,
    StrokePoint? lastPoint,
    DrawingEngineConfig config,
  ) {
    if (lastPoint == null) return true;
    final dt = newPoint.timestamp - lastPoint.timestamp;
    return dt >= config.timeThresholdMs;
  }
}

/// Evaluates sampling based on gesture velocity swings.
class VelocitySamplingStrategy extends SamplingStrategy {
  /// Creates a [VelocitySamplingStrategy].
  const VelocitySamplingStrategy();

  @override
  bool shouldSample(
    StrokePoint newPoint,
    StrokePoint? lastPoint,
    DrawingEngineConfig config,
  ) {
    if (lastPoint == null) return true;
    final dv = (newPoint.velocity - lastPoint.velocity).abs();
    return dv >= config.velocityThreshold;
  }
}
