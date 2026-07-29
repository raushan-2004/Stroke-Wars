import 'package:flutter/material.dart';

/// Uses a game-themed palette of deep purples, electric blues, and
/// gold accents.
/// Supports both light and dark variants.
abstract final class AppColors {
  /// Color scheme for light theme.
  static const AppColorScheme light = AppColorScheme(
    // Brand
    primary: Color(0xFF5B2AE0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8DAFF),
    onPrimaryContainer: Color(0xFF1D0060),

    // Secondary — Electric Blue
    secondary: Color(0xFF0094E8),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCE8FF),
    onSecondaryContainer: Color(0xFF001D32),

    // Tertiary — Gold Accent
    tertiary: Color(0xFFFFB700),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFFFFEDC2),
    onTertiaryContainer: Color(0xFF271900),

    // Surfaces
    background: Color(0xFFF8F5FF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEE8F4),
    onSurface: Color(0xFF1C1B1F),
    onSurfaceVariant: Color(0xFF49454E),

    // Error
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),

    // Outlines
    outline: Color(0xFF79757F),
    outlineVariant: Color(0xFFCAC4D0),

    // Misc
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF322F37),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFCEBDFF),
  );

  /// Color scheme for dark theme.
  static const AppColorScheme dark = AppColorScheme(
    // Brand
    primary: Color(0xFFCEBDFF),
    onPrimary: Color(0xFF300090),
    primaryContainer: Color(0xFF4400C8),
    onPrimaryContainer: Color(0xFFE8DAFF),

    // Secondary — Electric Blue
    secondary: Color(0xFF8DCEFF),
    onSecondary: Color(0xFF003355),
    secondaryContainer: Color(0xFF004A78),
    onSecondaryContainer: Color(0xFFCCE8FF),

    // Tertiary — Gold Accent
    tertiary: Color(0xFFFFCF70),
    onTertiary: Color(0xFF3A2700),
    tertiaryContainer: Color(0xFF553B00),
    onTertiaryContainer: Color(0xFFFFEDC2),

    // Surfaces
    background: Color(0xFF0E0B16),
    surface: Color(0xFF1A1625),
    surfaceVariant: Color(0xFF252030),
    onSurface: Color(0xFFE6E1E5),
    onSurfaceVariant: Color(0xFFCAC4D0),

    // Error
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),

    // Outlines
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454E),

    // Misc
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF322F37),
    inversePrimary: Color(0xFF5B2AE0),
  );

  /// Light mode glassmorphism card color.
  static const Color glassLight = Color(0x33FFFFFF);

  /// Dark mode glassmorphism card color.
  static const Color glassDark = Color(0x1AFFFFFF);

  /// Light mode glassmorphism card border color.
  static const Color glassBorderLight = Color(0x4DFFFFFF);

  /// Dark mode glassmorphism card border color.
  static const Color glassBorderDark = Color(0x26FFFFFF);

  /// Light mode canvas drawing background color.
  static const Color drawingCanvasLight = Color(0xFFFFFFFF);

  /// Dark mode canvas drawing background color.
  static const Color drawingCanvasDark = Color(0xFF1E1B2E);

  /// Green indicator color for a correct user guess.
  static const Color correctGuessGreen = Color(0xFF22C55E);

  /// Red indicator color for an incorrect user guess.
  static const Color incorrectGuessRed = Color(0xFFEF4444);

  /// Amber indicator color for warnings or time running out.
  static const Color warningAmber = Color(0xFFF59E0B);
}

/// A strongly-typed color scheme for Stroke Wars.
final class AppColorScheme {
  /// Creates an [AppColorScheme].
  const AppColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.error,
    required this.onError,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
  });

  /// Color used for primary branding and major UI interactive elements.
  final Color primary;

  /// Text/icon color drawn on top of the primary color.
  final Color onPrimary;

  /// Container color for primary elements.
  final Color primaryContainer;

  /// Text/icon color drawn on top of the primary container.
  final Color onPrimaryContainer;

  /// Secondary accent color (Electric Blue).
  final Color secondary;

  /// Text/icon color drawn on top of the secondary color.
  final Color onSecondary;

  /// Container color for secondary elements.
  final Color secondaryContainer;

  /// Text/icon color drawn on top of the secondary container.
  final Color onSecondaryContainer;

  /// Tertiary accent color (Gold Accent).
  final Color tertiary;

  /// Text/icon color drawn on top of the tertiary color.
  final Color onTertiary;

  /// Container color for tertiary elements.
  final Color tertiaryContainer;

  /// Text/icon color drawn on top of the tertiary container.
  final Color onTertiaryContainer;

  /// Background color of screen scaffolds.
  final Color background;

  /// Color of cards, sheets, and dialogs.
  final Color surface;

  /// Accent color variation for surfaces.
  final Color surfaceVariant;

  /// Text/icon color drawn on top of surfaces.
  final Color onSurface;

  /// Text/icon color variation drawn on top of surface variants.
  final Color onSurfaceVariant;

  /// Color used to indicate errors or destructive actions.
  final Color error;

  /// Text/icon color drawn on top of error color.
  final Color onError;

  /// Outlines and borders of text fields and dividers.
  final Color outline;

  /// Alternative border and divider color.
  final Color outlineVariant;

  /// Shadow color cast by cards and containers.
  final Color shadow;

  /// Overlay color for modal backdrops.
  final Color scrim;

  /// Surface color designed for contrast when needed in specific blocks.
  final Color inverseSurface;

  /// Text/icon color drawn on top of the inverse surface.
  final Color onInverseSurface;

  /// Primary color variation for use on dark/inverse backgrounds.
  final Color inversePrimary;
}
