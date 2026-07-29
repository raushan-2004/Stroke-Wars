import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized component sizing tokens for Stroke Wars Design Language
/// (SWDL).
///
/// Standardizes dimensions to ensure consistency and prevent magic sizing
/// values.
abstract final class SWSizes {
  // --- Icon Sizes ---

  /// Small icons (18dp).
  static double get iconSmall => 18.w;

  /// Medium icons (24dp).
  static double get iconMedium => 24.w;

  /// Large icons (32dp).
  static double get iconLarge => 32.w;

  // --- Avatar Sizes ---

  /// Small player avatar (36dp).
  static double get avatarSmall => 36.w;

  /// Medium player avatar (54dp).
  static double get avatarMedium => 54.w;

  /// Large player avatar (80dp).
  static double get avatarLarge => 80.w;

  // --- Button Heights ---

  /// Height for standard interactive buttons (50dp).
  static double get buttonHeight => 50.h;

  /// Height for compact interactive buttons (38dp).
  static double get buttonHeightSmall => 38.h;

  // --- Toolbars & Panels ---

  /// Standard app bar/header height (56dp).
  static double get headerHeight => 56.h;

  /// Standard drawing floating toolbar height (64dp).
  static double get drawingToolbarHeight => 64.h;

  /// Height for drawing color selection strip (48dp).
  static double get colorPickerHeight => 48.h;

  // --- HUD Elements ---

  /// Height of game timer display container (48dp).
  static double get hudTimerHeight => 48.h;

  /// Width of game timer display container (120dp).
  static double get hudTimerWidth => 120.w;

  /// Height of round progress bar (16dp).
  static double get roundIndicatorHeight => 16.h;
}
