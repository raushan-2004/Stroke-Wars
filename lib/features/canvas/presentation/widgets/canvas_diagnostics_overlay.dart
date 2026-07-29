import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/gesture_coordinator.dart';
import 'package:stroke_wars/features/canvas/application/input/input_pipeline.dart';

/// Diagnostics overlay presenting live performance metrics (FPS, Latency, Points) in debug builds.
class CanvasDiagnosticsOverlay extends ConsumerStatefulWidget {
  /// Creates a [CanvasDiagnosticsOverlay].
  const CanvasDiagnosticsOverlay({required this.gestureCoordinator, super.key});

  /// The active gesture coordinator reference.
  final GestureCoordinator gestureCoordinator;

  @override
  ConsumerState<CanvasDiagnosticsOverlay> createState() =>
      _CanvasDiagnosticsOverlayState();
}

class _CanvasDiagnosticsOverlayState
    extends ConsumerState<CanvasDiagnosticsOverlay> {
  int _fpsCount = 0;
  int _lastFps = 60;
  DateTime _lastFpsTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Completely omit in release builds
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    // Rough FPS count based on frame build draws
    final now = DateTime.now();
    _fpsCount++;
    if (now.difference(_lastFpsTime).inSeconds >= 1) {
      _lastFps = _fpsCount;
      _fpsCount = 0;
      _lastFpsTime = now;
    }

    final pipeline = ref.watch(inputPipelineProvider);
    final controller = ref.watch(canvasControllerProvider);
    final canvasState = controller.state;
    final zoom = canvasState.transform.getMaxScaleOnAxis();

    return Positioned(
      top: 80.h,
      left: 16.w,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.5),
              width: 1.r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DIAGNOSTICS HUD',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'FPS: $_lastFps',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
              Text(
                'Pointers: ${widget.gestureCoordinator.activePointers}',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
              Text(
                'Mode: ${widget.gestureCoordinator.currentType.name.toUpperCase()}',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
              Text(
                'Points Sampled: ${pipeline.pointsSampledCount}',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
              Text(
                'Latency: ${pipeline.lastInputLatencyMs.toStringAsFixed(1)} ms',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
              Text(
                'Zoom: ${zoom.toStringAsFixed(2)}x',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
              Text(
                'Brush: ${canvasState.selectedBrush.type.name.toUpperCase()} (${canvasState.selectedBrush.size.round()}px)',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
