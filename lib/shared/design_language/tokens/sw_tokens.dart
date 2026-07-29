import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized layout parameter tokens for Stroke Wars Design Language (SWDL).
abstract final class SWTokens {
  // --- Opacity Tokens ---

  /// Low opacity (0.12).
  static const double opacityLow = 0.12;

  /// Medium opacity (0.5).
  static const double opacityMedium = 0.5;

  /// High opacity (0.8).
  static const double opacityHigh = 0.8;

  // --- Blur Tokens (Glassmorphism) ---

  /// Light blur for subtle overlays (4.0).
  static double get blurSubtle => 4;

  /// Default glassmorphism background blur (12.0).
  static double get blurDefault => 12;

  /// Strong blur for modal dialog backdrops (24.0).
  static double get blurStrong => 24;

  // --- Borders & Strokes ---

  /// Fine border stroke (1dp).
  static double get borderThin => 1.r;

  /// Standard border stroke for interactive outlines (1.5dp).
  static double get borderMedium => 1.5.r;

  /// Bold outline stroke for drawing canvases or game states (3dp).
  static double get borderThick => 3.r;

  // --- Elevation Metrics ---

  /// Flat (0.0).
  static const double elevationFlat = 0;

  /// Low elevation overlay (2.0).
  static const double elevationLow = 2;

  /// Medium elevation overlay (6.0).
  static const double elevationMedium = 6;

  /// High elevation overlay (12.0).
  static const double elevationHigh = 12;
}
