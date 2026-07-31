/// Diagnostic class monitoring and recording rendering speeds, startup speeds, and memory allocations.
class PerformanceMonitor {
  final Map<String, List<double>> _metrics = {
    'frame_rendering_ms': [16.6, 16.7, 16.5],
    'memory_usage_mb': [120.0, 125.5, 130.2],
    'network_latency_ms': [45.0, 48.2, 52.1],
    'startup_time_ms': [450.0],
    'replay_loading_ms': [],
    'sync_duration_ms': [],
  };

  Map<String, List<double>> get metrics => Map.unmodifiable(_metrics);

  /// Appends a recorded value to a designated metric key.
  void recordMetric(String key, double value) {
    if (_metrics.containsKey(key)) {
      _metrics[key]!.add(value);
      if (_metrics[key]!.length > 100) {
        _metrics[key]!.removeAt(0); // Cap sizes
      }
    } else {
      _metrics[key] = [value];
    }
  }

  /// Calculates the average duration for a recorded metric.
  double getAverage(String key) {
    final list = _metrics[key];
    if (list == null || list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
