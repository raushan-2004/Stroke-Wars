/// Central configuration settings for tuning coordinate sampling and brush effects.
class DrawingEngineConfig {
  /// Creates a [DrawingEngineConfig].
  const DrawingEngineConfig({
    this.distanceThreshold = 2.0,
    this.timeThresholdMs = 8,
    this.velocityThreshold = 0.1,
    this.minPressure = 0.0,
    this.maxPressure = 1.0,
    this.defaultPressure = 1.0,
    this.velocitySmoothingFactor = 0.2,
    this.movingAverageWindowSize = 5,
    this.duplicateTolerance = 0.01,
    this.pressureScaleFactor = 1.0,
  });

  /// Minimum distance in pixels required to sample a new coordinate.
  final double distanceThreshold;

  /// Minimum elapsed time in milliseconds to sample a new coordinate.
  final int timeThresholdMs;

  /// Minimum velocity difference to trigger coordinate sampling.
  final double velocityThreshold;

  /// Minimum hardware pressure limit.
  final double minPressure;

  /// Maximum hardware pressure limit.
  final double maxPressure;

  /// Default pressure value when the hardware does not support pressure.
  final double defaultPressure;

  /// Velocity smoothing filter factor.
  final double velocitySmoothingFactor;

  /// Window size for the moving average stroke smoother.
  final int movingAverageWindowSize;

  /// Tolerance for detecting duplicate coordinate points.
  final double duplicateTolerance;

  /// Multiplier for scaling pressure sensitivity.
  final double pressureScaleFactor;

  /// Returns the default production configuration parameters.
  factory DrawingEngineConfig.defaultProduction() =>
      const DrawingEngineConfig();
}
