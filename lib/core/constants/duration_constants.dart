import 'package:flutter/material.dart';

/// Animation duration constants for consistent motion across the app.
abstract final class AppDurations {
  /// Instant — no animation.
  static const Duration instant = Duration.zero;

  /// Very fast micro-interaction (button tap).
  static const Duration fastest = Duration(milliseconds: 100);

  /// Fast UI feedback (ripple, icon state change).
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transition (page element appears).
  static const Duration normal = Duration(milliseconds: 250);

  /// Medium — screen transitions, card reveals.
  static const Duration medium = Duration(milliseconds: 350);

  /// Slow — emphasis animations, tooltips.
  static const Duration slow = Duration(milliseconds: 500);

  /// Very slow — onboarding, splash transitions.
  static const Duration slowest = Duration(milliseconds: 800);

  /// Lottie/Rive loop cycle duration.
  static const Duration animationCycle = Duration(milliseconds: 1500);
}

/// Standard [Curve] values used throughout Stroke Wars.
abstract final class AppCurves {
  /// Decelerating curve, useful for incoming elements.
  static const Curve decelerate = Curves.decelerate;

  /// Accelerating curve, useful for outgoing elements.
  static const Curve accelerate = Curves.easeIn;

  /// Standard ease-in-out curve.
  static const Curve standard = Curves.easeInOut;

  /// Overshooting elastic-out curve.
  static const Curve overshoot = Curves.elasticOut;

  /// Springy ease-out-back curve.
  static const Curve spring = Curves.easeOutBack;

  /// Sharp ease-in-out-cubic curve.
  static const Curve sharp = Curves.easeInOutCubic;
}
