import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/gesture_coordinator.dart';
import 'package:stroke_wars/features/canvas/application/input/input_pipeline.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_input_source.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/input_event.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/performance_caches.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/canvas_diagnostics_overlay.dart';
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
  final GestureCoordinator _gestureCoordinator = GestureCoordinator();

  Matrix4 _transformMatrix = Matrix4.identity();
  late Offset _lastFocalPoint;

  @override
  void dispose() {
    _pathCache.clear();
    _paintCache.clear();
    super.dispose();
  }

  DrawingInputSource _resolveInputSource(PointerDeviceKind kind) {
    switch (kind) {
      case PointerDeviceKind.touch:
        return DrawingInputSource.touch;
      case PointerDeviceKind.stylus:
        return DrawingInputSource.stylus;
      case PointerDeviceKind.mouse:
        return DrawingInputSource.mouse;
      default:
        return DrawingInputSource.touch;
    }
  }

  void _routePointerEvent(PointerEvent flutterEvent, Type eventType) {
    if (widget.isReadOnly) return;

    final source = _resolveInputSource(flutterEvent.kind);
    final localPos = flutterEvent.localPosition;

    Offset velocity = Offset.zero;
    if (flutterEvent is PointerMoveEvent) {
      velocity = flutterEvent.delta;
    }

    final timestamp = DateTime.now();

    InputEvent engineEvent;
    if (eventType == PointerDownEvent) {
      _gestureCoordinator.onPointerDown(flutterEvent.pointer);
      engineEvent = PointerDown(
        pointerId: flutterEvent.pointer,
        localPosition: localPos,
        timestamp: timestamp,
        pressure: flutterEvent.pressure,
        velocity: velocity,
        tilt: flutterEvent.tilt,
        inputSource: source,
      );
    } else if (eventType == PointerMoveEvent) {
      engineEvent = PointerMove(
        pointerId: flutterEvent.pointer,
        localPosition: localPos,
        timestamp: timestamp,
        pressure: flutterEvent.pressure,
        velocity: velocity,
        tilt: flutterEvent.tilt,
        inputSource: source,
      );
    } else if (eventType == PointerUpEvent) {
      _gestureCoordinator.onPointerUp(flutterEvent.pointer);
      engineEvent = PointerUp(
        pointerId: flutterEvent.pointer,
        localPosition: localPos,
        timestamp: timestamp,
        pressure: flutterEvent.pressure,
        velocity: velocity,
        tilt: flutterEvent.tilt,
        inputSource: source,
      );
    } else {
      _gestureCoordinator.onPointerCancel(flutterEvent.pointer);
      engineEvent = PointerCancel(
        pointerId: flutterEvent.pointer,
        localPosition: localPos,
        timestamp: timestamp,
        pressure: flutterEvent.pressure,
        velocity: velocity,
        tilt: flutterEvent.tilt,
        inputSource: source,
      );
    }

    // Single finger draw validation
    if (!widget.isMoveMode && _gestureCoordinator.shouldDraw) {
      final controller = ref.read(canvasControllerProvider);
      ref
          .read(inputPipelineProvider)
          .handleEvent(
            engineEvent,
            _transformMatrix,
            controller.state.selectedBrush,
          );
    }
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
            return Stack(
              children: [
                Listener(
                  onPointerDown: (e) => _routePointerEvent(e, PointerDownEvent),
                  onPointerMove: (e) => _routePointerEvent(e, PointerMoveEvent),
                  onPointerUp: (e) => _routePointerEvent(e, PointerUpEvent),
                  onPointerCancel: (e) =>
                      _routePointerEvent(e, PointerCancelEvent),
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _lastFocalPoint = details.localFocalPoint;
                    },
                    onScaleUpdate: (details) {
                      if (widget.isMoveMode ||
                          _gestureCoordinator.shouldTransform) {
                        final translation =
                            details.localFocalPoint - _lastFocalPoint;
                        _lastFocalPoint = details.localFocalPoint;

                        final nextMatrix = Matrix4.copy(_transformMatrix)
                          ..translate(translation.dx, translation.dy);

                        if (details.scale != 1.0) {
                          final focalPointCanvas = _screenToCanvas(
                            details.localFocalPoint,
                            _transformMatrix,
                          );
                          nextMatrix
                            ..translate(
                              focalPointCanvas.dx,
                              focalPointCanvas.dy,
                            )
                            ..scale(details.scale)
                            ..translate(
                              -focalPointCanvas.dx,
                              -focalPointCanvas.dy,
                            );
                        }

                        controller.updateTransform(nextMatrix);
                      }
                    },
                    child: ClipRect(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                          painter: StrokeRenderer(
                            canvasState: canvasState,
                            pathCache: _pathCache,
                            paintCache: _paintCache,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Diagnostics Overlay HUD (visible in debug builds only)
                CanvasDiagnosticsOverlay(
                  gestureCoordinator: _gestureCoordinator,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
