import 'package:stroke_wars/features/canvas/domain/models/canvas_command.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Manages undo and redo stacks for command operations.
class HistoryManager {
  final List<CanvasCommand> _undoStack = [];
  final List<CanvasCommand> _redoStack = [];

  /// Returns whether there are commands available to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Returns whether there are commands available to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Executes a new command, clears the redo stack, and pushes it to the undo stack.
  List<Stroke> executeCommand(
    CanvasCommand command,
    List<Stroke> currentStrokes,
  ) {
    _redoStack.clear();
    _undoStack.add(command);
    return command.execute(currentStrokes);
  }

  /// Undoes the last command, shifting it to the redo stack.
  List<Stroke> undo(List<Stroke> currentStrokes) {
    if (_undoStack.isEmpty) return currentStrokes;
    final command = _undoStack.removeLast();
    _redoStack.add(command);
    return command.undo(currentStrokes);
  }

  /// Redoes the last undone command, shifting it back to the undo stack.
  List<Stroke> redo(List<Stroke> currentStrokes) {
    if (_redoStack.isEmpty) return currentStrokes;
    final command = _redoStack.removeLast();
    _undoStack.add(command);
    return command.execute(currentStrokes);
  }

  /// Clears undo/redo command stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
