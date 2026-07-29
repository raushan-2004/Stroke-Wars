/// Holds coordinates, timestamps, and input metadata for a single drawing coordinate.
class StrokePoint {
  /// Creates a [StrokePoint].
  const StrokePoint({
    required this.x,
    required this.y,
    required this.timestamp,
    this.pressure = 1.0,
    this.velocity = 0.0,
  });

  /// X coordinate relative to canvas bounds.
  final double x;

  /// Y coordinate relative to canvas bounds.
  final double y;

  /// Milliseconds relative to the starting time of the parent stroke.
  final int timestamp;

  /// Input pressure (defaults to 1.0 for mouse/touch inputs).
  final double pressure;

  /// Current gesture velocity at this coordinate.
  final double velocity;

  /// Converts this point to a JSON map.
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    't': timestamp,
    'p': pressure,
    'v': velocity,
  };

  /// Creates a [StrokePoint] from a JSON map.
  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    timestamp: json['t'] as int,
    pressure: (json['p'] as num?)?.toDouble() ?? 1.0,
    velocity: (json['v'] as num?)?.toDouble() ?? 0.0,
  );
}
