import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/performance_caches.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/stroke_renderer.dart';

/// Interactive canvas rendering drawing gestures and supporting Zoom / Pan viewport modes.
class DrawingCanvas extends ConsumerStatefulWidget {
  /// Creates a [DrawingCanvas].
  const DrawingCanvas({
    required this.playerId,
    required this.isReadOnly,
    required this.isMoveMode,
    super.key,
  });

  /// The active drawing player's UUID.
  final String playerId;

  /// Whether drawing gestures are disabled (e.g. spectator or guesser mode).
  final bool isReadOnly;

  /// Whether gestures pan/zoom the viewport instead of painting strokes.
  final bool isMoveMode;

  @override
  ConsumerState<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  final PathCache _pathCache = PathCache();
  final PaintCache _paintCache = PaintCache();

  // Active matrix transform tracker
  Matrix4 _transformMatrix = Matrix4.identity();
  late Offset _lastFocalPoint;

  @override
  void dispose() {
    _pathCache.clear();
    _paintCache.clear();
    super.dispose();
  }

  Offset _screenToCanvas(Offset screenOffset, Matrix4 transform) {
    try {
      final invert = Matrix4.inverted(transform);
      return MatrixUtils.transformPoint(invert, screenOffset);
    } catch (_) {
      return screenOffset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(canvasControllerProvider);
    final renderQueue = ref.watch(renderQueueProvider);

    return ListenableBuilder(
      listenable: renderQueue,
      builder: (context, child) {
        final canvasState = renderQueue.currentState;
        _transformMatrix = canvasState.transform;

        return LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onScaleStart: (details) {
                _lastFocalPoint = details.localFocalPoint;
                if (!widget.isReadOnly && !widget.isMoveMode) {
                  final canvasPos = _screenToCanvas(
                    details.localFocalPoint,
                    _transformMatrix,
                  );
                  controller.startStroke(
                    widget.playerId,
                    canvasState.selectedBrush,
                  );
                  controller.appendPoint(canvasPos.dx, canvasPos.dy);
                }
              },
              onScaleUpdate: (details) {
                if (widget.isMoveMode) {
                  // Perform viewport panning/zooming translation
                  final translation = details.localFocalPoint - _lastFocalPoint;
                  _lastFocalPoint = details.localFocalPoint;

                  final nextMatrix = Matrix4.copy(_transformMatrix)
                    ..translate(translation.dx, translation.dy);

                  // Apply zoom scaling factor if user pinches
                  if (details.scale != 1.0) {
                    final focalPointCanvas = _screenToCanvas(
                      details.localFocalPoint,
                      _transformMatrix,
                    );
                    nextMatrix
                      ..translate(focalPointCanvas.dx, focalPointCanvas.dy)
                      ..scale(details.scale)
                      ..translate(-focalPointCanvas.dx, -focalPointCanvas.dy);
                  }

                  controller.updateTransform(nextMatrix);
                } else if (!widget.isReadOnly) {
                  // Perform brush painting stroke coordinate append
                  final canvasPos = _screenToCanvas(
                    details.localFocalPoint,
                    _transformMatrix,
                  );
                  controller.appendPoint(canvasPos.dx, canvasPos.dy);
                }
              },
              onScaleEnd: (details) {
                if (!widget.isReadOnly && !widget.isMoveMode) {
                  controller.finishStroke();
                }
              },
              child: ClipRect(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: StrokeRenderer(
                      canvasState: canvasState,
                      pathCache: _pathCache,
                      paintCache: _paintCache,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
