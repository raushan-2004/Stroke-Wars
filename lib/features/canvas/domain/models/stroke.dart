import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';

/// Represents a completed freehand drawing line with cached coordinate bounds.
class Stroke {
  /// Creates a [Stroke].
  const Stroke({
    required this.id,
    required this.playerId,
    required this.brushId,
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.createdTime,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Unique stroke identifier.
  final String id;

  /// Player ID responsible for drawing this line.
  final String playerId;

  /// Identifier for the brush style used.
  final String brushId;

  /// Immutable list of coordinates in this stroke.
  final List<StrokePoint> points;

  /// Color hex code (e.g. '#9C27B0').
  final String color;

  /// Line thickness.
  final double width;

  /// Paint opacity (0.0 to 1.0).
  final double opacity;

  /// Creation timestamp.
  final DateTime createdTime;

  /// Cached leftmost coordinate bound.
  final double left;

  /// Cached topmost coordinate bound.
  final double top;

  /// Cached rightmost coordinate bound.
  final double right;

  /// Cached bottommost coordinate bound.
  final double bottom;

  /// Converts this stroke to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'brushId': brushId,
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
    'opacity': opacity,
    'createdTime': createdTime.toIso8601String(),
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };

  /// Restores a [Stroke] from a JSON map.
  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    id: json['id'] as String,
    playerId: json['playerId'] as String,
    brushId: json['brushId'] as String,
    points: (json['points'] as List<dynamic>)
        .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    color: json['color'] as String,
    width: (json['width'] as num).toDouble(),
    opacity: (json['opacity'] as num).toDouble(),
    createdTime: DateTime.parse(json['createdTime'] as String),
    left: (json['left'] as num).toDouble(),
    top: (json['top'] as num).toDouble(),
    right: (json['right'] as num).toDouble(),
    bottom: (json['bottom'] as num).toDouble(),
  );
}
