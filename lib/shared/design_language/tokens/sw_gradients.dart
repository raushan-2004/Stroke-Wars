import 'package:flutter/material.dart';

/// Centralized gradients for Stroke Wars Design Language (SWDL).
abstract final class SWGradients {
  /// Primary brand gradient (Vibrant Purple to Electric Blue).
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
  );

  /// Victory / Gold reward gradient.
  static const LinearGradient victory = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFFD700), Color(0xFFF59E0B)],
  );

  /// Danger / Alert gradient.
  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
  );

  /// XP progression gradient.
  static const LinearGradient xp = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  /// Season pass / Progression level gradient.
  static const LinearGradient season = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  /// Premium tier / Gold highlight gradient.
  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
  );

  /// Neon backing glow effect gradient.
  static const RadialGradient radialGlow = RadialGradient(
    colors: [Color(0x336366F1), Color(0x00000000)],
    radius: 0.8,
  );
}
