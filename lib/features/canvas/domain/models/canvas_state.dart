import 'package:flutter/material.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Immutable representation of the complete drawing canvas state.
class CanvasState {
  /// Creates a [CanvasState].
  const CanvasState({
    required this.strokes,
    this.activeStroke,
    required this.transform,
    required this.selectedBrush,
    this.canUndo = false,
    this.canRedo = false,
  });

  /// Complete list of drawn strokes.
  final List<Stroke> strokes;

  /// The active stroke currently being drawn (null if not drawing).
  final Stroke? activeStroke;

  /// Viewport transformation matrix (handling Zoom & Pan).
  final Matrix4 transform;

  /// Currently selected brush tool settings.
  final BrushSettings selectedBrush;

  /// Whether there are actions available to undo in history.
  final bool canUndo;

  /// Whether there are actions available to redo in history.
  final bool canRedo;

  /// Generates a copy with updated properties, supporting null setting for activeStroke.
  CanvasState copyWith({
    List<Stroke>? strokes,
    Stroke? Function()? activeStroke,
    Matrix4? transform,
    BrushSettings? selectedBrush,
    bool? canUndo,
    bool? canRedo,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      activeStroke: activeStroke != null ? activeStroke() : this.activeStroke,
      transform: transform ?? this.transform,
      selectedBrush: selectedBrush ?? this.selectedBrush,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  /// Initial default empty state of the canvas.
  factory CanvasState.initial() => CanvasState(
    strokes: const [],
    activeStroke: null,
    transform: Matrix4.identity(),
    selectedBrush: const BrushSettings(
      type: BrushType.classic,
      size: 8.0,
      opacity: 1.0,
      color: Colors.white,
    ),
  );
}
