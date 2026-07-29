import 'package:flutter/material.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_input_source.dart';

/// Immutable model representing an active user drawing session interaction.
class DrawingSession {
  /// Creates a [DrawingSession].
  const DrawingSession({
    required this.pointerId,
    required this.strokeId,
    required this.inputSource,
    required this.startTime,
    required this.activeBrush,
    required this.viewportTransform,
  });

  /// The unique gesture pointer ID tracking this session.
  final int pointerId;

  /// The UUID of the stroke being constructed in this session.
  final String strokeId;

  /// The origin input hardware device.
  final DrawingInputSource inputSource;

  /// The initiation timestamp of the drawing stroke.
  final DateTime startTime;

  /// The selected brush settings used at session start.
  final BrushSettings activeBrush;

  /// The viewport transformation matrix active at session start.
  final Matrix4 viewportTransform;
}
