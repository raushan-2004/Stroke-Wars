import 'package:flutter/foundation.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';

/// Buffers and coordinates canvas state updates to prevent UI drawing lag.
class RenderQueue extends ChangeNotifier {
  CanvasState _currentState = CanvasState.initial();

  /// Gets the currently buffered active state of the canvas.
  CanvasState get currentState => _currentState;

  /// Pushes a new canvas state into the render queue, notifying downstream painters.
  void enqueue(CanvasState newState) {
    _currentState = newState;
    notifyListeners();
  }
}
