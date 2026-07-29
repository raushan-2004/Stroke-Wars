import 'package:flutter/material.dart';

/// Available brush styles supported by the SECF engine.
enum BrushType {
  /// Standard solid anti-aliased path.
  classic,

  /// Semi-translucent flat tip path.
  marker,

  /// Glowing stroke with a bright core and soft neon aura shadows.
  neon,

  /// Thin, textured, slightly textured path.
  pencil,

  /// Aliased pixelated stair-step path.
  pixel,

  /// Soft scattered spray-paint texture.
  airbrush,
}

/// Immutable configuration settings for active canvas drawing brushes.
class BrushSettings {
  /// Creates a [BrushSettings] configuration.
  const BrushSettings({
    required this.type,
    required this.size,
    required this.opacity,
    required this.color,
  });

  /// The active brush style.
  final BrushType type;

  /// Line thickness width.
  final double size;

  /// Paint transparency (0.0 to 1.0).
  final double opacity;

  /// Active drawing color.
  final Color color;

  /// Generates a copy with updated properties.
  BrushSettings copyWith({
    BrushType? type,
    double? size,
    double? opacity,
    Color? color,
  }) {
    return BrushSettings(
      type: type ?? this.type,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      color: color ?? this.color,
    );
  }
}
