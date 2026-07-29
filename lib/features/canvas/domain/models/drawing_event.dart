import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';

/// Base abstract class for all drawing action events consumed by SECF.
abstract class DrawingEvent {
  /// Base constructor.
  const DrawingEvent();

  /// Converts this event to a JSON map.
  Map<String, dynamic> toJson();

  /// Creates a [DrawingEvent] from a JSON map.
  factory DrawingEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'stroke_started':
        return StrokeStarted.fromJson(json);
      case 'point_added':
        return PointAdded.fromJson(json);
      case 'stroke_finished':
        return StrokeFinished.fromJson(json);
      case 'canvas_cleared':
        return CanvasCleared.fromJson(json);
      case 'undo_performed':
        return UndoPerformed.fromJson(json);
      case 'redo_performed':
        return RedoPerformed.fromJson(json);
      default:
        throw ArgumentError('Unknown drawing event type: $type');
    }
  }
}

/// Dispatched when a user initiates a new gesture stroke line.
class StrokeStarted extends DrawingEvent {
  /// Creates a [StrokeStarted] event.
  const StrokeStarted({
    required this.strokeId,
    required this.playerId,
    required this.brushId,
    required this.color,
    required this.width,
    required this.opacity,
    required this.timestamp,
  });

  /// The unique stroke identifier.
  final String strokeId;

  /// The drawing player's UUID.
  final String playerId;

  /// Active brush style identifier.
  final String brushId;

  /// The line color hex code.
  final String color;

  /// Brush size width.
  final double width;

  /// Opacity level.
  final double opacity;

  /// Start timestamp.
  final DateTime timestamp;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'stroke_started',
    'strokeId': strokeId,
    'playerId': playerId,
    'brushId': brushId,
    'color': color,
    'width': width,
    'opacity': opacity,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Restores a [StrokeStarted] event from JSON.
  factory StrokeStarted.fromJson(Map<String, dynamic> json) => StrokeStarted(
    strokeId: json['strokeId'] as String,
    playerId: json['playerId'] as String,
    brushId: json['brushId'] as String,
    color: json['color'] as String,
    width: (json['width'] as num).toDouble(),
    opacity: (json['opacity'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Dispatched as intermediate points are appended to the active stroke.
class PointAdded extends DrawingEvent {
  /// Creates a [PointAdded] event.
  const PointAdded({required this.strokeId, required this.point});

  /// The parent stroke identifier.
  final String strokeId;

  /// The coordinate point appended.
  final StrokePoint point;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'point_added',
    'strokeId': strokeId,
    'point': point.toJson(),
  };

  /// Restores a [PointAdded] event from JSON.
  factory PointAdded.fromJson(Map<String, dynamic> json) => PointAdded(
    strokeId: json['strokeId'] as String,
    point: StrokePoint.fromJson(json['point'] as Map<String, dynamic>),
  );
}

/// Dispatched when the drawing gesture concludes and the stroke completes.
class StrokeFinished extends DrawingEvent {
  /// Creates a [StrokeFinished] event.
  const StrokeFinished({required this.strokeId});

  /// The stroke identifier that finished.
  final String strokeId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'stroke_finished',
    'strokeId': strokeId,
  };

  /// Restores a [StrokeFinished] event from JSON.
  factory StrokeFinished.fromJson(Map<String, dynamic> json) =>
      StrokeFinished(strokeId: json['strokeId'] as String);
}

/// Dispatched when the entire canvas is cleared.
class CanvasCleared extends DrawingEvent {
  /// Creates a [CanvasCleared] event.
  const CanvasCleared();

  @override
  Map<String, dynamic> toJson() => {'type': 'canvas_cleared'};

  /// Restores a [CanvasCleared] event from JSON.
  factory CanvasCleared.fromJson(Map<String, dynamic> json) =>
      const CanvasCleared();
}

/// Dispatched when an undo operation is triggered.
class UndoPerformed extends DrawingEvent {
  /// Creates an [UndoPerformed] event.
  const UndoPerformed();

  @override
  Map<String, dynamic> toJson() => {'type': 'undo_performed'};

  /// Restores an [UndoPerformed] event from JSON.
  factory UndoPerformed.fromJson(Map<String, dynamic> json) =>
      const UndoPerformed();
}

/// Dispatched when a redo operation is triggered.
class RedoPerformed extends DrawingEvent {
  /// Creates a [RedoPerformed] event.
  const RedoPerformed();

  @override
  Map<String, dynamic> toJson() => {'type': 'redo_performed'};

  /// Restores a [RedoPerformed] event from JSON.
  factory RedoPerformed.fromJson(Map<String, dynamic> json) =>
      const RedoPerformed();
}
