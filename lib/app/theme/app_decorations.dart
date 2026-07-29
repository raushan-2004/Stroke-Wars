import 'package:flutter/material.dart';

import 'package:stroke_wars/app/theme/app_colors.dart';

/// Reusable decoration builders for Stroke Wars.
///
/// Provides glassmorphism and gradient decorations for game UI elements.
abstract final class AppDecorations {
  /// Glassmorphism card for light mode.
  static BoxDecoration glassCardLight({
    double borderRadius = 16,
    double blurOpacity = 0.3,
  }) {
    return BoxDecoration(
      color: AppColors.glassLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorderLight, width: 1.5),
    );
  }

  /// Glassmorphism card for dark mode.
  static BoxDecoration glassCardDark({double borderRadius = 16}) {
    return BoxDecoration(
      color: AppColors.glassDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorderDark, width: 1.5),
    );
  }

  /// Returns the appropriate glass card based on [brightness].
  static BoxDecoration glassCard({
    required Brightness brightness,
    double borderRadius = 16,
  }) {
    return brightness == Brightness.dark
        ? glassCardDark(borderRadius: borderRadius)
        : glassCardLight(borderRadius: borderRadius);
  }

  /// Primary brand gradient — purple to blue.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B2AE0), Color(0xFF0094E8)],
  );

  /// Dark background gradient for game screens.
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E0B16), Color(0xFF1A1625), Color(0xFF0E0B16)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gold accent gradient for scores and achievements.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFB700), Color(0xFFFF8C00)],
  );

  /// Standard container shadow.
  static List<BoxShadow> softShadow({
    Color color = const Color(0x1A000000),
    double blurRadius = 20,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  /// Colored glow effect for interactive elements.
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.4}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ];
  }
}
