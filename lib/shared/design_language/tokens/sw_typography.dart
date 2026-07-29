import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_colors.dart';

/// Centralized typography definitions for Stroke Wars Design Language (SWDL).
///
/// Features:
/// - [GoogleFonts.rajdhani] for game indicators, HUD, score, timer,
///   and prompt displays.
/// - [GoogleFonts.nunito] for clean, readable body text, buttons,
///   and UI screens.
abstract final class SWTypography {
  // --- Standard UI Typography (Nunito) ---

  /// Ultra-large display title.
  static TextStyle get displayXL => GoogleFonts.nunito(
    fontSize: 34.sp,
    fontWeight: FontWeight.w900,
    color: SWColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Main screen title.
  static TextStyle get displayLarge => GoogleFonts.nunito(
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    color: SWColors.textPrimary,
  );

  /// Section heading.
  static TextStyle get heading => GoogleFonts.nunito(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: SWColors.textPrimary,
  );

  /// Default title for list elements.
  static TextStyle get title => GoogleFonts.nunito(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: SWColors.textPrimary,
  );

  /// Standard UI body text.
  static TextStyle get body => GoogleFonts.nunito(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: SWColors.textSecondary,
  );

  /// Micro elements description text.
  static TextStyle get caption => GoogleFonts.nunito(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: SWColors.textMuted,
  );

  /// Interactive button text.
  static TextStyle get button => GoogleFonts.nunito(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: SWColors.textPrimary,
  );

  // --- Game HUD & Specialized Typography (Rajdhani) ---

  /// Numeric score displays.
  static TextStyle get score => GoogleFonts.rajdhani(
    fontSize: 32.sp,
    fontWeight: FontWeight.w700,
    color: SWColors.victory,
    letterSpacing: 1,
  );

  /// Numeric timers / countdowns.
  static TextStyle get timer => GoogleFonts.rajdhani(
    fontSize: 48.sp,
    fontWeight: FontWeight.w700,
    color: SWColors.textPrimary,
  );

  /// HUD metadata labels.
  static TextStyle get gameLabel => GoogleFonts.rajdhani(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: SWColors.textSecondary,
  );

  /// Numeric scoreboard listings.
  static TextStyle get leaderboardNumber => GoogleFonts.rajdhani(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    color: SWColors.textPrimary,
  );

  /// Display of the active secret word to draw or guess.
  static TextStyle get wordPrompt => GoogleFonts.rajdhani(
    fontSize: 26.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 3,
    color: SWColors.textPrimary,
  );

  /// Active round info counter.
  static TextStyle get roundCounter => GoogleFonts.rajdhani(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: SWColors.secondary,
  );
}
