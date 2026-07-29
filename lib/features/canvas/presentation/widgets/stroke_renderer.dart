import 'package:flutter/material.dart';

import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/brush_registry.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/performance_caches.dart';

/// Highly optimized [CustomPainter] that draws anti-aliased path strokes from cached models.
class StrokeRenderer extends CustomPainter {
  /// Creates a [StrokeRenderer] with performance cache hooks.
  StrokeRenderer({
    required this.canvasState,
    required this.pathCache,
    required this.paintCache,
  });

  /// The active frame state of the canvas.
  final CanvasState canvasState;

  /// Cache preventing recalculation of Flutter [Path] bounds.
  final PathCache pathCache;

  /// Cache preventing allocation of [Paint] configurations.
  final PaintCache paintCache;

  @override
  void paint(Canvas canvas, Size size) {
    // Isolate rendering within viewport clipping boundaries
    canvas.clipRect(Offset.zero & size);

    // Persist viewport matrix transforms (handling Zoom & Pan)
    canvas.save();
    canvas.transform(canvasState.transform.storage);

    // Draw completed strokes
    for (final stroke in canvasState.strokes) {
      // Check if stroke intersects visible viewport boundaries (viewport culling)
      if (!_isStrokeInViewport(stroke, size)) continue;
      _paintStroke(canvas, stroke);
    }

    // Draw temporary active drawing stroke
    final active = canvasState.activeStroke;
    if (active != null) {
      _paintStroke(canvas, active);
    }

    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = pathCache.getPath(stroke);
    final paint = paintCache.getPaint(
      color: _hexToColor(stroke.color),
      width: stroke.width,
      opacity: stroke.opacity,
    );

    final renderer = BrushRegistry.getRenderer(
      BrushType.values.firstWhere(
        (b) => b.name == stroke.brushId,
        orElse: () => BrushType.classic,
      ),
    );

    renderer.draw(canvas, path, paint, stroke);
  }

  bool _isStrokeInViewport(Stroke stroke, Size viewportSize) {
    // Basic bounding-box viewport intersection culling
    // Checks if stroke overlaps with visible region (expanded to prevent edge clipping)
    const margin = 20.0;
    final viewportRect = Rect.fromLTRB(
      -margin,
      -margin,
      viewportSize.width + margin,
      viewportSize.height + margin,
    );
    final strokeRect = Rect.fromLTRB(
      stroke.left,
      stroke.top,
      stroke.right,
      stroke.bottom,
    );
    return viewportRect.overlaps(strokeRect);
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  bool shouldRepaint(covariant StrokeRenderer oldDelegate) {
    return oldDelegate.canvasState != canvasState;
  }
}
