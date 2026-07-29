import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';

/// Builder class responsible for efficiently constructing completed strokes with calculated bounds.
class StrokeBuilder {
  /// Creates a [StrokeBuilder] for a new stroke series.
  StrokeBuilder({
    required this.id,
    required this.playerId,
    required this.brushId,
    required this.color,
    required this.width,
    required this.opacity,
  }) : createdTime = DateTime.now();

  /// Unique stroke identifier.
  final String id;

  /// Drawing player ID.
  final String playerId;

  /// Active brush style identifier.
  final String brushId;

  /// Hex color code.
  final String color;

  /// Brush size width.
  final double width;

  /// Opacity level.
  final double opacity;

  /// Start timestamp.
  final DateTime createdTime;

  final List<StrokePoint> _points = [];

  /// Appends a new coordinate coordinate to the active drawing series.
  void appendPoint(StrokePoint point) {
    _points.add(point);
  }

  /// Appends raw coordinates as a [StrokePoint].
  void addRawPoint(
    double x,
    double y,
    int elapsedMs, {
    double pressure = 1.0,
    double velocity = 0.0,
  }) {
    _points.add(
      StrokePoint(
        x: x,
        y: y,
        timestamp: elapsedMs,
        pressure: pressure,
        velocity: velocity,
      ),
    );
  }

  /// Returns whether this builder contains no coordinates.
  bool get isEmpty => _points.isEmpty;

  /// Compiles points, computes bounds, and returns a finalized immutable [Stroke] object.
  Stroke build() {
    if (_points.isEmpty) {
      return Stroke(
        id: id,
        playerId: playerId,
        brushId: brushId,
        points: const [],
        color: color,
        width: width,
        opacity: opacity,
        createdTime: createdTime,
        left: 0.0,
        top: 0.0,
        right: 0.0,
        bottom: 0.0,
      );
    }

    double left = _points.first.x;
    double top = _points.first.y;
    double right = _points.first.x;
    double bottom = _points.first.y;

    for (final p in _points) {
      if (p.x < left) left = p.x;
      if (p.y < top) top = p.y;
      if (p.x > right) right = p.x;
      if (p.y > bottom) bottom = p.y;
    }

    return Stroke(
      id: id,
      playerId: playerId,
      brushId: brushId,
      points: List.unmodifiable(_points),
      color: color,
      width: width,
      opacity: opacity,
      createdTime: createdTime,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }
}
