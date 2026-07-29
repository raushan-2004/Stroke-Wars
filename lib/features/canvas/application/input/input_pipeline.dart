import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_input_source.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_session.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/input_event.dart';
import 'package:stroke_wars/features/canvas/application/input/brush_processor.dart';
import 'package:stroke_wars/features/canvas/application/input/input_filter.dart';
import 'package:stroke_wars/features/canvas/application/input/input_strategy.dart';
import 'package:stroke_wars/features/canvas/application/input/palm_rejection.dart';
import 'package:stroke_wars/features/canvas/application/input/pressure_processor.dart';
import 'package:stroke_wars/features/canvas/application/input/sampling_strategy.dart';
import 'package:stroke_wars/features/canvas/application/input/stroke_smoother.dart';

part 'input_pipeline.g.dart';

/// Central input pipeline orchestrating strategies, filters, smoothers, and controllers.
class InputPipeline {
  /// Creates an [InputPipeline] binding to [controller].
  InputPipeline({required this.controller, DrawingEngineConfig? config})
    : config = config ?? DrawingEngineConfig.defaultProduction(),
      _filter = const InputFilter(),
      _pressureProcessor = const PressureProcessor(),
      _brushProcessor = const BrushProcessor(),
      _smoother = const MovingAverageSmoother(),
      _palmRejection = const DefaultStrategy(),
      _samplers = const [
        DistanceSamplingStrategy(),
        TimeSamplingStrategy(),
        VelocitySamplingStrategy(),
      ];

  /// Active drawing controller.
  final CanvasController controller;

  /// Pipeline tuning parameters.
  final DrawingEngineConfig config;

  final InputFilter _filter;
  final PressureProcessor _pressureProcessor;
  final BrushProcessor _brushProcessor;
  final StrokeSmoother _smoother;
  final PalmRejectionStrategy _palmRejection;
  final List<SamplingStrategy> _samplers;

  DrawingSession? _activeSession;
  InputEvent? _lastEvent;
  final List<StrokePoint> _rawPoints = [];

  /// Sampled coordinates count in current stroke session.
  int pointsSampledCount = 0;

  /// Elapsed milliseconds between event dispatch and execution.
  double lastInputLatencyMs = 0.0;

  /// Dispatches raw event details through strategies and filters down to the CanvasController.
  void handleEvent(
    InputEvent rawEvent,
    Matrix4 transform,
    BrushSettings brush,
  ) {
    // 1. Preprocess event according to target device strategies
    final strategy = _resolveStrategy(rawEvent.inputSource);
    final event = strategy.preprocess(rawEvent, config);

    // 2. Evaluate palm-blocking configurations
    if (_palmRejection.shouldReject(event)) return;

    // 3. Filter noise and tremors
    if (!_filter.shouldProcess(event, _lastEvent, config)) return;
    _lastEvent = event;

    // Diagnose gesture latencies
    lastInputLatencyMs = DateTime.now()
        .difference(event.timestamp)
        .inMilliseconds
        .toDouble();

    // Convert coordinates using transformed matrices
    final canvasPos = _screenToCanvas(event.localPosition, transform);

    if (event is PointerDown) {
      _rawPoints.clear();
      pointsSampledCount = 0;

      final session = DrawingSession(
        pointerId: event.pointerId,
        strokeId: controller.state.activeStroke?.id ?? 'stroke-temp',
        inputSource: event.inputSource,
        startTime: event.timestamp,
        activeBrush: brush,
        viewportTransform: transform,
      );
      _activeSession = session;

      final initialPoint = _processPoint(canvasPos, event, brush);
      _rawPoints.add(initialPoint);
      pointsSampledCount++;

      controller.startStroke(
        controller.state.activeStroke?.playerId ?? 'practice-bot',
        brush,
      );
      controller.appendPoint(
        canvasPos.dx,
        canvasPos.dy,
        pressure: initialPoint.pressure,
        velocity: initialPoint.velocity,
      );
    } else if (event is PointerMove) {
      final session = _activeSession;
      if (session == null) return;

      final candidatePoint = _processPoint(canvasPos, event, brush);
      final lastPoint = _rawPoints.isNotEmpty ? _rawPoints.last : null;

      // 4. Evaluate composite samplers to decide whether to append coordinate
      bool shouldSample = false;
      for (final sampler in _samplers) {
        if (sampler.shouldSample(candidatePoint, lastPoint, config)) {
          shouldSample = true;
          break;
        }
      }

      if (shouldSample) {
        _rawPoints.add(candidatePoint);
        pointsSampledCount++;

        // Apply moving average smoothing
        final smoothed = _smoother.smooth(_rawPoints, config);
        final latestSmoothed = smoothed.last;

        controller.appendPoint(
          latestSmoothed.x,
          latestSmoothed.y,
          pressure: latestSmoothed.pressure,
          velocity: latestSmoothed.velocity,
        );
      }
    } else if (event is PointerUp || event is PointerCancel) {
      _activeSession = null;
      controller.finishStroke();
    }
  }

  StrokePoint _processPoint(
    Offset canvasPos,
    InputEvent event,
    BrushSettings brush,
  ) {
    final velocityVal = event.velocity.distance;
    final normPressure = _pressureProcessor.normalize(event.pressure, config);

    final basePoint = StrokePoint(
      x: canvasPos.dx,
      y: canvasPos.dy,
      timestamp: event.timestamp.millisecondsSinceEpoch,
      pressure: normPressure,
      velocity: velocityVal,
    );

    // Apply dynamic modifiers — width and opacity feed into future variable-width stroke rendering
    final adjustedPressure =
        _brushProcessor.calculateWidth(brush.size, basePoint, brush.type) /
        brush.size.clamp(1.0, 64.0);

    return StrokePoint(
      x: canvasPos.dx,
      y: canvasPos.dy,
      timestamp: event.timestamp.millisecondsSinceEpoch,
      pressure: normPressure * adjustedPressure.clamp(0.1, 1.0),
      velocity: velocityVal,
    );
  }

  InputStrategy _resolveStrategy(DrawingInputSource source) {
    switch (source) {
      case DrawingInputSource.touch:
        return const TouchStrategy();
      case DrawingInputSource.stylus:
        return const StylusStrategy();
      case DrawingInputSource.mouse:
        return const MouseStrategy();
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
}

/// Riverpod provider exposing the initialized [InputPipeline].
@riverpod
InputPipeline inputPipeline(InputPipelineRef ref) {
  final controller = ref.watch(canvasControllerProvider);
  return InputPipeline(controller: controller);
}
