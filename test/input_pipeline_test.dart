import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/canvas/application/input/brush_processor.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/gesture_coordinator.dart';
import 'package:stroke_wars/features/canvas/application/input/input_filter.dart';
import 'package:stroke_wars/features/canvas/application/input/pressure_processor.dart';
import 'package:stroke_wars/features/canvas/application/input/sampling_strategy.dart';
import 'package:stroke_wars/features/canvas/application/input/stroke_smoother.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_input_source.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_engine_config.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/drawing_session.dart';
import 'package:stroke_wars/features/canvas/domain/models/input/input_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';

void main() {
  group('Input Pipeline & Drawing Tools (IPDT) - Unit Tests', () {
    const config = DrawingEngineConfig(
      distanceThreshold: 2.0,
      timeThresholdMs: 8,
      velocityThreshold: 0.1,
      minPressure: 0,
      maxPressure: 1,
      defaultPressure: 1,
      movingAverageWindowSize: 3,
      duplicateTolerance: 0.01,
    );

    // ────────────────────────────────────────────
    // DrawingEngineConfig
    // ────────────────────────────────────────────
    test('DrawingEngineConfig.defaultProduction creates correct defaults', () {
      const cfg = DrawingEngineConfig();
      expect(cfg.distanceThreshold, 2.0);
      expect(cfg.timeThresholdMs, 8);
      expect(cfg.movingAverageWindowSize, 5);
      expect(cfg.defaultPressure, 1.0);
    });

    // ────────────────────────────────────────────
    // DrawingSession
    // ────────────────────────────────────────────
    test('DrawingSession holds correct immutable properties', () {
      final session = DrawingSession(
        pointerId: 42,
        strokeId: 'stroke-xyz',
        inputSource: DrawingInputSource.touch,
        startTime: DateTime(2026),
        activeBrush: const BrushSettings(
          type: BrushType.neon,
          size: 12,
          opacity: 0.9,
          color: Colors.cyan,
        ),
        viewportTransform: Matrix4.identity(),
      );

      expect(session.pointerId, 42);
      expect(session.strokeId, 'stroke-xyz');
      expect(session.inputSource, DrawingInputSource.touch);
      expect(session.activeBrush.type, BrushType.neon);
    });

    // ────────────────────────────────────────────
    // InputFilter
    // ────────────────────────────────────────────
    test('InputFilter rejects duplicate coordinates', () {
      const filter = InputFilter();
      final event1 = PointerMove(
        pointerId: 1,
        localPosition: const Offset(10, 10),
        timestamp: DateTime(2026),
        inputSource: DrawingInputSource.touch,
      );
      final event2 = PointerMove(
        pointerId: 1,
        localPosition: const Offset(10.005, 10.005),
        timestamp: DateTime(2026),
        inputSource: DrawingInputSource.touch,
      );

      expect(filter.shouldProcess(event1, null, config), isTrue);
      expect(filter.shouldProcess(event2, event1, config), isFalse);
    });

    test('InputFilter passes sufficiently moved coordinates', () {
      const filter = InputFilter();
      final event1 = PointerMove(
        pointerId: 1,
        localPosition: const Offset(0, 0),
        timestamp: DateTime(2026),
        inputSource: DrawingInputSource.touch,
      );
      final event2 = PointerMove(
        pointerId: 1,
        localPosition: const Offset(5, 5),
        timestamp: DateTime(2026),
        inputSource: DrawingInputSource.touch,
      );

      expect(filter.shouldProcess(event2, event1, config), isTrue);
    });

    // ────────────────────────────────────────────
    // DistanceSamplingStrategy
    // ────────────────────────────────────────────
    test(
      'DistanceSamplingStrategy samples when distance exceeds threshold',
      () {
        const strategy = DistanceSamplingStrategy();
        const p1 = StrokePoint(x: 0, y: 0, timestamp: 0);
        const p2 = StrokePoint(x: 3, y: 4, timestamp: 10); // dist = 5.0 > 2.0
        const p3 = StrokePoint(x: 1, y: 0, timestamp: 20); // dist = 1.0 < 2.0

        expect(strategy.shouldSample(p1, null, config), isTrue);
        expect(strategy.shouldSample(p2, p1, config), isTrue);
        expect(strategy.shouldSample(p3, p1, config), isFalse);
      },
    );

    // ────────────────────────────────────────────
    // TimeSamplingStrategy
    // ────────────────────────────────────────────
    test('TimeSamplingStrategy samples when elapsed exceeds threshold', () {
      const strategy = TimeSamplingStrategy();
      const p1 = StrokePoint(x: 0, y: 0, timestamp: 0);
      const p2 = StrokePoint(x: 0, y: 0, timestamp: 10); // 10ms > 8ms
      const p3 = StrokePoint(x: 0, y: 0, timestamp: 5); // 5ms < 8ms

      expect(strategy.shouldSample(p2, p1, config), isTrue);
      expect(strategy.shouldSample(p3, p1, config), isFalse);
    });

    // ────────────────────────────────────────────
    // StrokeSmoother — MovingAverage
    // ────────────────────────────────────────────
    test(
      'MovingAverageSmoother smooths a path maintaining start/end anchors',
      () {
        const smoother = MovingAverageSmoother();
        final points = [
          const StrokePoint(x: 0, y: 0, timestamp: 0),
          const StrokePoint(x: 10, y: 50, timestamp: 10),
          const StrokePoint(x: 20, y: 10, timestamp: 20),
          const StrokePoint(x: 30, y: 60, timestamp: 30),
          const StrokePoint(x: 40, y: 20, timestamp: 40),
        ];

        final smoothed = smoother.smooth(points, config);
        expect(smoothed.length, points.length);
        // Anchors preserved
        expect(smoothed.first.x, 0);
        expect(smoothed.last.x, 40);
        // Interior coordinates should be averaged, not raw
        expect(smoothed[2].y, isNot(equals(10.0)));
      },
    );

    test('MovingAverageSmoother returns original points when count < 3', () {
      const smoother = MovingAverageSmoother();
      final twoPoints = [
        const StrokePoint(x: 0, y: 0, timestamp: 0),
        const StrokePoint(x: 10, y: 10, timestamp: 10),
      ];
      final result = smoother.smooth(twoPoints, config);
      expect(result, twoPoints);
    });

    // ────────────────────────────────────────────
    // PressureProcessor
    // ────────────────────────────────────────────
    test('PressureProcessor normalizes pressure correctly', () {
      const processor = PressureProcessor();
      expect(processor.normalize(0, config), 1.0); // zero → default
      expect(processor.normalize(1, config), 1.0);
      expect(processor.normalize(0.5, config), closeTo(0.5, 0.01));
      expect(processor.normalize(2.0, config), 1.0); // clamped to max
    });

    // ────────────────────────────────────────────
    // BrushProcessor
    // ────────────────────────────────────────────
    test('BrushProcessor calculates dynamic width and opacity', () {
      const processor = BrushProcessor();
      const slowPoint = StrokePoint(
        x: 0,
        y: 0,
        timestamp: 0,
        pressure: 1,
        velocity: 0,
      );
      const fastPoint = StrokePoint(
        x: 0,
        y: 0,
        timestamp: 0,
        pressure: 0.5,
        velocity: 14,
      );

      final slowWidth = processor.calculateWidth(
        10,
        slowPoint,
        BrushType.classic,
      );
      final fastWidth = processor.calculateWidth(
        10,
        fastPoint,
        BrushType.classic,
      );

      // High velocity → thinner stroke
      expect(slowWidth, greaterThan(fastWidth));
    });

    // ────────────────────────────────────────────
    // GestureCoordinator — Pointer Lifecycle
    // ────────────────────────────────────────────
    test('GestureCoordinator routes single finger to drawing mode', () {
      final coordinator = GestureCoordinator();
      expect(coordinator.currentType, GestureType.idle);

      coordinator.onPointerDown(1);
      expect(coordinator.shouldDraw, isTrue);
      expect(coordinator.shouldTransform, isFalse);

      coordinator.onPointerUp(1);
      expect(coordinator.currentType, GestureType.idle);
    });

    test('GestureCoordinator routes multi-finger to viewport mode', () {
      final coordinator = GestureCoordinator();
      coordinator.onPointerDown(1);
      coordinator.onPointerDown(2);
      expect(coordinator.shouldDraw, isFalse);
      expect(coordinator.shouldTransform, isTrue);

      coordinator.onPointerUp(1);
      coordinator.onPointerUp(2);
      expect(coordinator.currentType, GestureType.idle);
    });

    // ────────────────────────────────────────────
    // DrawingEventBus
    // ────────────────────────────────────────────
    test('DrawingEventBus publishes events to subscribers', () async {
      final bus = DrawingEventBus();
      final received = <DrawingEvent>[];
      final sub = bus.stream.listen(received.add);

      bus.publish(const CanvasCleared());
      bus.publish(const UndoPerformed());

      await Future<void>.delayed(Duration.zero);

      expect(received.length, 2);
      expect(received[0], isA<CanvasCleared>());
      expect(received[1], isA<UndoPerformed>());

      await sub.cancel();
      bus.dispose();
    });

    test('DrawingEventBus ignores publish after dispose', () async {
      final bus = DrawingEventBus();
      bus.dispose();
      // Should not throw
      expect(() => bus.publish(const CanvasCleared()), returnsNormally);
    });
  });
}
