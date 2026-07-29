import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized spacing tokens for Stroke Wars Design Language (SWDL).
///
/// Ensures layout proportions scale responsively based on device dimensions.
abstract final class SWSpacing {
  /// Extra small spacing (4dp).
  static double get xs => 4.w;

  /// Small spacing (8dp).
  static double get sm => 8.w;

  /// Medium-small spacing (12dp).
  static double get md => 12.w;

  /// Standard spacing (16dp).
  static double get lg => 16.w;

  /// Medium-large spacing (20dp).
  static double get xl => 20.w;

  /// Double extra large spacing (24dp).
  static double get xxl => 24.w;

  /// Triple extra large spacing (32dp).
  static double get xxxl => 32.w;

  /// Huge spacing (40dp).
  static double get huge => 40.w;

  /// Epic spacing (48dp).
  static double get epic => 48.w;

  /// Massive spacing (64dp).
  static double get massive => 64.w;

  /// Gigantic spacing (96dp).
  static double get gigantic => 96.w;
}
