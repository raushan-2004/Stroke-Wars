/// Type classification of active gesture motions.
enum GestureType {
  /// No pointer interaction active.
  idle,

  /// User is drawing a path line (typically single pointer).
  drawing,

  /// User is moving or zooming the viewport (typically multi-pointer).
  viewPort,
}

/// Tracks pointer count to coordinate and isolate drawing gestures from viewport transformations.
class GestureCoordinator {
  int _activePointers = 0;
  GestureType _currentType = GestureType.idle;

  /// Gets the count of active touch contacts.
  int get activePointers => _activePointers;

  /// Gets the currently resolved gesture type classification.
  GestureType get currentType => _currentType;

  /// Increment pointer count and update gesture state.
  void onPointerDown(int pointerId) {
    _activePointers++;
    _updateGestureType();
  }

  /// Decrement pointer count and update gesture state.
  void onPointerUp(int pointerId) {
    _activePointers = (_activePointers - 1).clamp(0, 20);
    _updateGestureType();
  }

  /// Decrement pointer count on cancellation.
  void onPointerCancel(int pointerId) {
    _activePointers = (_activePointers - 1).clamp(0, 20);
    _updateGestureType();
  }

  void _updateGestureType() {
    if (_activePointers == 0) {
      _currentType = GestureType.idle;
    } else if (_activePointers == 1) {
      _currentType = GestureType.drawing;
    } else {
      _currentType = GestureType.viewPort;
    }
  }

  /// Returns whether coordinates should be routed to the brush drawing builder.
  bool get shouldDraw => _currentType == GestureType.drawing;

  /// Returns whether gestures should move/scale the viewport.
  bool get shouldTransform => _currentType == GestureType.viewPort;

  /// Resets pointers and gestural states.
  void reset() {
    _activePointers = 0;
    _currentType = GestureType.idle;
  }
}
