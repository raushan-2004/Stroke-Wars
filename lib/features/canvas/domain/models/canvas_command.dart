import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Command pattern abstraction representing an undoable canvas drawing operation.
abstract interface class CanvasCommand {
  /// Applies the command to the current list of strokes, returning the updated list.
  List<Stroke> execute(List<Stroke> currentStrokes);

  /// Reverses the command on the current list of strokes, returning the previous list.
  List<Stroke> undo(List<Stroke> currentStrokes);
}

/// Command adding a completed stroke to the canvas.
class AddStrokeCommand implements CanvasCommand {
  /// Creates an [AddStrokeCommand].
  const AddStrokeCommand(this.stroke);

  /// The completed stroke being drawn.
  final Stroke stroke;

  @override
  List<Stroke> execute(List<Stroke> currentStrokes) {
    return List.of(currentStrokes)..add(stroke);
  }

  @override
  List<Stroke> undo(List<Stroke> currentStrokes) {
    return List.of(currentStrokes)..removeWhere((s) => s.id == stroke.id);
  }
}

/// Command removing a specific stroke (e.g. from an eraser tool).
class RemoveStrokeCommand implements CanvasCommand {
  /// Creates a [RemoveStrokeCommand].
  const RemoveStrokeCommand(this.stroke);

  /// The stroke to be removed.
  final Stroke stroke;

  @override
  List<Stroke> execute(List<Stroke> currentStrokes) {
    return List.of(currentStrokes)..removeWhere((s) => s.id == stroke.id);
  }

  @override
  List<Stroke> undo(List<Stroke> currentStrokes) {
    return List.of(currentStrokes)..add(stroke);
  }
}

/// Command that clears the entire canvas but remembers state for full undos.
class ClearCanvasCommand implements CanvasCommand {
  /// Creates a [ClearCanvasCommand].
  ClearCanvasCommand();

  List<Stroke>? _previousStrokes;

  @override
  List<Stroke> execute(List<Stroke> currentStrokes) {
    _previousStrokes = List.of(currentStrokes);
    return const [];
  }

  @override
  List<Stroke> undo(List<Stroke> currentStrokes) {
    return _previousStrokes ?? currentStrokes;
  }
}
