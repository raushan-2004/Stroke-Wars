import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized border radius tokens for Stroke Wars Design Language (SWDL).
abstract final class SWRadius {
  // --- Raw double values ---

  /// Small corner radius (4dp).
  static double get sVal => 4.r;

  /// Medium corner radius (8dp).
  static double get mVal => 8.r;

  /// Large corner radius (12dp).
  static double get lVal => 12.r;

  /// Extra large corner radius (16dp).
  static double get xlVal => 16.r;

  /// Double extra large corner radius (24dp).
  static double get xxlVal => 24.r;

  /// Triple extra large corner radius (32dp).
  static double get xxxlVal => 32.r;

  /// Fully circular corner radius (999dp).
  static double get circularVal => 999.r;

  // --- BorderRadius objects ---

  /// Small border radius (4dp).
  static BorderRadius get s => BorderRadius.circular(sVal);

  /// Medium border radius (8dp).
  static BorderRadius get m => BorderRadius.circular(mVal);

  /// Large border radius (12dp).
  static BorderRadius get l => BorderRadius.circular(lVal);

  /// Extra large border radius (16dp).
  static BorderRadius get xl => BorderRadius.circular(xlVal);

  /// Double extra large border radius (24dp).
  static BorderRadius get xxl => BorderRadius.circular(xxlVal);

  /// Triple extra large border radius (32dp).
  static BorderRadius get xxxl => BorderRadius.circular(xxxlVal);

  /// Fully circular border radius (999dp).
  static BorderRadius get circular => BorderRadius.circular(circularVal);
}
