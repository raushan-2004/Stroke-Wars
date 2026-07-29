import 'dart:math';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_command.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/history_manager.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/stroke_builder.dart';

part 'canvas_controller.g.dart';

/// Exposes active rendering queue configuration.
@riverpod
RenderQueue renderQueue(RenderQueueRef ref) {
  return RenderQueue();
}

/// Central controller managing drawing states, command history, and event dispatch streams.
class CanvasController {
  /// Creates a [CanvasController].
  CanvasController({required this.renderQueue})
    : _history = HistoryManager(),
      _state = CanvasState.initial();

  /// Target rendering queue buffering canvas frames.
  final RenderQueue renderQueue;

  final HistoryManager _history;
  CanvasState _state;
  StrokeBuilder? _activeBuilder;
  DateTime? _strokeStartTime;

  final List<DrawingEvent> _events = [];

  /// Returns the current active immutable canvas state.
  CanvasState get state => _state;

  /// Returns the history log of drawing events generated.
  List<DrawingEvent> get events => List.unmodifiable(_events);

  /// Initializes a new drawing stroke.
  void startStroke(String playerId, BrushSettings brush) {
    final id = _generateV4Uuid();
    final startTime = DateTime.now();
    _strokeStartTime = startTime;

    final builder = StrokeBuilder(
      id: id,
      playerId: playerId,
      brushId: brush.type.name,
      color: _colorToHex(brush.color),
      width: brush.size,
      opacity: brush.opacity,
    );
    _activeBuilder = builder;

    final event = StrokeStarted(
      strokeId: id,
      playerId: playerId,
      brushId: brush.type.name,
      color: _colorToHex(brush.color),
      width: brush.size,
      opacity: brush.opacity,
      timestamp: startTime,
    );
    _events.add(event);

    _updateState(
      _state.copyWith(
        activeStroke: () => builder.build(),
        selectedBrush: brush,
      ),
    );
  }

  /// Appends coordinates to the current drawing stroke.
  void appendPoint(
    double x,
    double y, {
    double pressure = 1.0,
    double velocity = 0.0,
  }) {
    final builder = _activeBuilder;
    final startTime = _strokeStartTime;
    if (builder == null || startTime == null) return;

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final point = StrokePoint(
      x: x,
      y: y,
      timestamp: elapsed,
      pressure: pressure,
      velocity: velocity,
    );
    builder.appendPoint(point);

    final event = PointAdded(strokeId: builder.id, point: point);
    _events.add(event);

    _updateState(_state.copyWith(activeStroke: () => builder.build()));
  }

  /// Finalizes and commits the active drawing stroke.
  void finishStroke() {
    final builder = _activeBuilder;
    if (builder == null) return;

    final stroke = builder.build();
    _activeBuilder = null;
    _strokeStartTime = null;

    final event = StrokeFinished(strokeId: stroke.id);
    _events.add(event);

    if (stroke.points.isNotEmpty) {
      final command = AddStrokeCommand(stroke);
      final newStrokes = _history.executeCommand(command, _state.strokes);
      _updateState(
        _state.copyWith(
          strokes: newStrokes,
          activeStroke: () => null,
          canUndo: _history.canUndo,
          canRedo: _history.canRedo,
        ),
      );
    } else {
      _updateState(_state.copyWith(activeStroke: () => null));
    }
  }

  /// Performs undo operation on the command history stack.
  void undo() {
    if (!_history.canUndo) return;
    final newStrokes = _history.undo(_state.strokes);
    _events.add(const UndoPerformed());
    _updateState(
      _state.copyWith(
        strokes: newStrokes,
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      ),
    );
  }

  /// Performs redo operation on the command history stack.
  void redo() {
    if (!_history.canRedo) return;
    final newStrokes = _history.redo(_state.strokes);
    _events.add(const RedoPerformed());
    _updateState(
      _state.copyWith(
        strokes: newStrokes,
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      ),
    );
  }

  /// Clears the entire canvas drawing, pushing a ClearCanvasCommand to history.
  void clear() {
    if (_state.strokes.isEmpty) return;
    final command = ClearCanvasCommand();
    final newStrokes = _history.executeCommand(command, _state.strokes);
    _events.add(const CanvasCleared());
    _updateState(
      _state.copyWith(
        strokes: newStrokes,
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      ),
    );
  }

  /// Resets the history command stacks.
  void resetHistory() {
    _history.clear();
    _updateState(
      _state.copyWith(
        strokes: const [],
        activeStroke: () => null,
        canUndo: false,
        canRedo: false,
      ),
    );
  }

  /// Updates active viewport transformation matrix.
  void updateTransform(Matrix4 transform) {
    _updateState(_state.copyWith(transform: transform));
  }

  /// Updates active brush tool selection parameters.
  void selectBrush(BrushSettings brush) {
    _updateState(_state.copyWith(selectedBrush: brush));
  }

  void _updateState(CanvasState newState) {
    _state = newState;
    renderQueue.enqueue(newState);
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  String _generateV4Uuid() {
    final random = Random.secure();
    String hexDigit(int value) => value.toRadixString(16);
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        buffer.write('-');
      }
      if (i == 12) {
        buffer.write('4'); // Version 4
      } else if (i == 16) {
        buffer.write(hexDigit(random.nextInt(4) + 8));
      } else {
        buffer.write(hexDigit(random.nextInt(16)));
      }
    }
    return buffer.toString();
  }
}

/// Riverpod provider to access the [CanvasController] instance.
@riverpod
CanvasController canvasController(CanvasControllerRef ref) {
  final queue = ref.watch(renderQueueProvider);
  return CanvasController(renderQueue: queue);
}
