import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_command.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/brush_registry.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/brush_renderer.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/history_manager.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/stroke_builder.dart';

void main() {
  group('Stroke Engine & Canvas Framework (SECF) - Unit Tests', () {
    test('StrokePoint JSON serialization & deserialization', () {
      const point = StrokePoint(
        x: 10.5,
        y: 20.0,
        timestamp: 150,
        pressure: 0.8,
        velocity: 4.2,
      );

      final jsonMap = point.toJson();
      expect(jsonMap['x'], 10.5);
      expect(jsonMap['y'], 20.0);
      expect(jsonMap['t'], 150);
      expect(jsonMap['p'], 0.8);
      expect(jsonMap['v'], 4.2);

      final restored = StrokePoint.fromJson(jsonMap);
      expect(restored.x, 10.5);
      expect(restored.y, 20.0);
      expect(restored.timestamp, 150);
      expect(restored.pressure, 0.8);
      expect(restored.velocity, 4.2);
    });

    test('StrokeBuilder constructs immutable Stroke and computes bounds', () {
      final builder = StrokeBuilder(
        id: 'stroke-1',
        playerId: 'player-1',
        brushId: 'classic',
        color: '#ff0000',
        width: 5.0,
        opacity: 1.0,
      );

      expect(builder.isEmpty, isTrue);

      builder.appendPoint(const StrokePoint(x: 10.0, y: 15.0, timestamp: 0));
      builder.appendPoint(const StrokePoint(x: 5.0, y: 30.0, timestamp: 50));
      builder.appendPoint(const StrokePoint(x: 25.0, y: 8.0, timestamp: 100));

      expect(builder.isEmpty, isFalse);

      final stroke = builder.build();

      expect(stroke.id, 'stroke-1');
      expect(stroke.playerId, 'player-1');
      expect(stroke.points.length, 3);
      expect(stroke.width, 5.0);

      // Verify bounds compilation (left, top, right, bottom)
      expect(stroke.left, 5.0); // min x
      expect(stroke.top, 8.0); // min y
      expect(stroke.right, 25.0); // max x
      expect(stroke.bottom, 30.0); // max y
    });

    test('CanvasState initial and copyWith immutability', () {
      final state = CanvasState.initial();
      expect(state.strokes, isEmpty);
      expect(state.activeStroke, isNull);
      expect(state.canUndo, isFalse);

      final customBrush = const BrushSettings(
        type: BrushType.neon,
        size: 12.0,
        opacity: 0.8,
        color: Colors.green,
      );

      final nextState = state.copyWith(
        selectedBrush: customBrush,
        canUndo: true,
      );

      expect(nextState.strokes, isEmpty);
      expect(nextState.selectedBrush.type, BrushType.neon);
      expect(nextState.selectedBrush.size, 12.0);
      expect(nextState.canUndo, isTrue);
      // Original remains unchanged
      expect(state.canUndo, isFalse);
      expect(state.selectedBrush.type, BrushType.classic);
    });

    test('HistoryManager executes, undoes, and redoes commands', () {
      final history = HistoryManager();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);

      final stroke = Stroke(
        id: 'stroke-1',
        playerId: 'player-1',
        brushId: 'classic',
        points: const [StrokePoint(x: 0, y: 0, timestamp: 0)],
        color: '#ffffff',
        width: 2.0,
        opacity: 1.0,
        createdTime: DateTime.now(),
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
      );

      List<Stroke> currentStrokes = const [];

      // 1. Execute AddStrokeCommand
      final command = AddStrokeCommand(stroke);
      currentStrokes = history.executeCommand(command, currentStrokes);

      expect(currentStrokes.length, 1);
      expect(currentStrokes.first.id, 'stroke-1');
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);

      // 2. Undo
      currentStrokes = history.undo(currentStrokes);
      expect(currentStrokes, isEmpty);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);

      // 3. Redo
      currentStrokes = history.redo(currentStrokes);
      expect(currentStrokes.length, 1);
      expect(currentStrokes.first.id, 'stroke-1');
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);

      // 4. Clear
      final clearCommand = ClearCanvasCommand();
      currentStrokes = history.executeCommand(clearCommand, currentStrokes);
      expect(currentStrokes, isEmpty);

      // 5. Undo Clear
      currentStrokes = history.undo(currentStrokes);
      expect(currentStrokes.length, 1);
      expect(currentStrokes.first.id, 'stroke-1');
    });

    test('BrushRegistry returns correct BrushRenderer strategies', () {
      final classic = BrushRegistry.getRenderer(BrushType.classic);
      expect(classic, isA<ClassicBrushRenderer>());

      final neon = BrushRegistry.getRenderer(BrushType.neon);
      expect(neon, isA<NeonBrushRenderer>());

      final pixel = BrushRegistry.getRenderer(BrushType.pixel);
      expect(pixel, isA<PixelBrushRenderer>());
    });

    test('DrawingEvents JSON serialization & deserialization', () {
      final time = DateTime.parse('2026-07-29T12:00:00Z');
      final event1 = StrokeStarted(
        strokeId: 'stroke-abc',
        playerId: 'player-xyz',
        brushId: 'neon',
        color: '#ff00ff',
        width: 10.0,
        opacity: 0.9,
        timestamp: time,
      );

      final jsonMap1 = event1.toJson();
      expect(jsonMap1['type'], 'stroke_started');
      expect(jsonMap1['strokeId'], 'stroke-abc');
      expect(jsonMap1['width'], 10.0);

      final restored1 = DrawingEvent.fromJson(jsonMap1) as StrokeStarted;
      expect(restored1.strokeId, 'stroke-abc');
      expect(restored1.playerId, 'player-xyz');
      expect(restored1.brushId, 'neon');
      expect(restored1.width, 10.0);
      expect(restored1.opacity, 0.9);
      expect(restored1.timestamp, time);

      // PointAdded serialization
      const point = StrokePoint(x: 12.0, y: 15.0, timestamp: 200);
      final event2 = PointAdded(strokeId: 'stroke-abc', point: point);
      final jsonMap2 = event2.toJson();

      final restored2 = DrawingEvent.fromJson(jsonMap2) as PointAdded;
      expect(restored2.strokeId, 'stroke-abc');
      expect(restored2.point.x, 12.0);
      expect(restored2.point.timestamp, 200);
    });
  });
}
