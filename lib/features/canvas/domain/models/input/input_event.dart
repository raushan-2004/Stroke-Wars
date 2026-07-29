import 'package:flutter/material.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_input_source.dart';

/// Represents explicit states of a pointer interaction lifecycle.
enum PointerLifecycle {
  /// No pointer interaction active.
  idle,

  /// Pointer has contacted the sensor, but no motion has occurred.
  pressed,

  /// Pointer is moving across the sensor, active drawing.
  drawing,

  /// Pointer is lifting off the sensor.
  ending,

  /// The drawing gesture is complete.
  completed,

  /// The pointer has been cancelled or cleaned up.
  disposed,
}

/// Base abstract class for all engine-decoupled pointer input events.
abstract class InputEvent {
  /// Base constructor.
  const InputEvent({
    required this.pointerId,
    required this.localPosition,
    required this.timestamp,
    this.pressure = 1.0,
    this.velocity = const Offset(0, 0),
    this.tilt = 0.0,
    required this.inputSource,
  });

  /// The tracking pointer identifier.
  final int pointerId;

  /// Normalized screen coordinate offset.
  final Offset localPosition;

  /// Capture timestamp.
  final DateTime timestamp;

  /// Stylus pressure (defaults to 1.0).
  final double pressure;

  /// Movement velocity vector.
  final Offset velocity;

  /// Stylus tilt angle (defaults to 0.0).
  final double tilt;

  /// The pointer device origin source.
  final DrawingInputSource inputSource;
}

/// Dispatched when contact is first registered.
class PointerDown extends InputEvent {
  /// Creates a [PointerDown] event.
  const PointerDown({
    required super.pointerId,
    required super.localPosition,
    required super.timestamp,
    super.pressure,
    super.velocity,
    super.tilt,
    required super.inputSource,
  });
}

/// Dispatched as pointer slides across the viewport.
class PointerMove extends InputEvent {
  /// Creates a [PointerMove] event.
  const PointerMove({
    required super.pointerId,
    required super.localPosition,
    required super.timestamp,
    super.pressure,
    super.velocity,
    super.tilt,
    required super.inputSource,
  });
}

/// Dispatched when pointer contact releases normally.
class PointerUp extends InputEvent {
  /// Creates a [PointerUp] event.
  const PointerUp({
    required super.pointerId,
    required super.localPosition,
    required super.timestamp,
    super.pressure,
    super.velocity,
    super.tilt,
    required super.inputSource,
  });
}

/// Dispatched when pointer tracking is aborted (e.g. system interrupts).
class PointerCancel extends InputEvent {
  /// Creates a [PointerCancel] event.
  const PointerCancel({
    required super.pointerId,
    required super.localPosition,
    required super.timestamp,
    super.pressure,
    super.velocity,
    super.tilt,
    required super.inputSource,
  });
}
