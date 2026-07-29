import 'package:flutter/material.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Abstract interface for drawing paths of a specific brush type.
abstract interface class BrushRenderer {
  /// Renders the specified path onto the canvas.
  void draw(Canvas canvas, Path path, Paint paint, Stroke stroke);
}

/// Standard anti-aliased classic round brush path renderer.
class ClassicBrushRenderer implements BrushRenderer {
  /// Creates a [ClassicBrushRenderer].
  const ClassicBrushRenderer();

  @override
  void draw(Canvas canvas, Path path, Paint paint, Stroke stroke) {
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }
}

/// Semi-translucent flat marker tip path renderer (inherits classic for now).
class MarkerBrushRenderer extends ClassicBrushRenderer {
  /// Creates a [MarkerBrushRenderer].
  const MarkerBrushRenderer();
}

/// Glowing neon line path renderer (inherits classic for now).
class NeonBrushRenderer extends ClassicBrushRenderer {
  /// Creates a [NeonBrushRenderer].
  const NeonBrushRenderer();
}

/// Aliased pixelated stair-step path renderer (inherits classic for now).
class PixelBrushRenderer extends ClassicBrushRenderer {
  /// Creates a [PixelBrushRenderer].
  const PixelBrushRenderer();
}

/// Scattered spray airbrush path renderer (inherits classic for now).
class AirbrushBrushRenderer extends ClassicBrushRenderer {
  /// Creates a [AirbrushBrushRenderer].
  const AirbrushBrushRenderer();
}
