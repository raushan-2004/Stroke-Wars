import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing constants for consistent layout across the app.
///
/// Uses [ScreenUtil] for responsive scaling. All values are based on
/// the design reference frame of 390×844 (iPhone 14 Pro).
abstract final class AppSpacing {
  /// Extra small spacing (4dp).
  static double get xs => 4.w;

  /// Small spacing (8dp).
  static double get sm => 8.w;

  /// Medium spacing (12dp).
  static double get md => 12.w;

  /// Large spacing (16dp).
  static double get lg => 16.w;

  /// Extra large spacing (20dp).
  static double get xl => 20.w;

  /// Double extra large spacing (24dp).
  static double get xxl => 24.w;

  /// Triple extra large spacing (32dp).
  static double get xxxl => 32.w;

  /// Huge spacing (48dp).
  static double get huge => 48.w;

  /// Massive spacing (64dp).
  static double get massive => 64.w;

  /// Standard horizontal page padding.
  static double get pagePaddingH => 20.w;

  /// Standard vertical page padding.
  static double get pagePaddingV => 24.h;
}
