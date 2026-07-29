import 'package:flutter/material.dart';

/// Centralized animation durations and curves for Stroke Wars Design
/// Language (SWDL).
abstract final class SWAnimations {
  // --- Animation Durations ---

  /// Fast interaction feedback (button hover, tap highlight) — 100ms.
  static const Duration durationFast = Duration(milliseconds: 100);

  /// Medium transition duration (card entries, toggle flip) — 250ms.
  static const Duration durationMedium = Duration(milliseconds: 250);

  /// Slow full layout duration (dialog slide-in, onboarding page change)
  /// — 450ms.
  static const Duration durationSlow = Duration(milliseconds: 450);

  /// Duration for full screen transition animations — 350ms.
  static const Duration durationPage = Duration(milliseconds: 350);

  /// Duration for modal dialog animations — 300ms.
  static const Duration durationDialog = Duration(milliseconds: 300);

  // --- Animation Curves ---

  /// Smooth deceleration curve for slide-in panels.
  static const Curve curveDecelerate = Curves.decelerate;

  /// Springy overshoot curve for HUD badges and success indicators.
  static const Curve curveOvershoot = Curves.easeOutBack;

  /// Custom elastic spring curve.
  static const Curve curveSpring = Curves.elasticOut;

  /// Bouncy feedback curve for score counts and round completions.
  static const Curve curveBounce = Curves.bounceOut;
}
