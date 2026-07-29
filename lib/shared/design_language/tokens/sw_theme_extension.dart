import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_animations.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_colors.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_gradients.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_typography.dart';

/// Theme extension for SWDL colors, enabling light/dark mode interpolation.
class SWColorsExtension extends ThemeExtension<SWColorsExtension> {
  /// Creates an [SWColorsExtension].
  const SWColorsExtension({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHighest,
    required this.border,
    required this.borderActive,
    required this.online,
    required this.offline,
    required this.lan,
    required this.bluetooth,
    required this.xp,
    required this.victory,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onPrimary,
    required this.onSecondary,
    required this.glassBackground,
    required this.glassBorder,
  });

  /// Primary brand color.
  final Color primary;

  /// Secondary brand color.
  final Color secondary;

  /// Scaffold background color.
  final Color background;

  /// Base surface color.
  final Color surface;

  /// Container surface color.
  final Color surfaceContainer;

  /// Highest container surface color.
  final Color surfaceContainerHighest;

  /// Default border color.
  final Color border;

  /// Focused/Active border color.
  final Color borderActive;

  /// Online player state color.
  final Color online;

  /// Offline player state color.
  final Color offline;

  /// Local network mode state color.
  final Color lan;

  /// Bluetooth mode state color.
  final Color bluetooth;

  /// Experience progress state color.
  final Color xp;

  /// Victory/Award highlight state color.
  final Color victory;

  /// Success state color.
  final Color success;

  /// Danger/Destructive state color.
  final Color danger;

  /// Warning state color.
  final Color warning;

  /// Info state color.
  final Color info;

  /// Primary text color.
  final Color textPrimary;

  /// Secondary text color.
  final Color textSecondary;

  /// Muted text color.
  final Color textMuted;

  /// Foreground color drawn on primary background.
  final Color onPrimary;

  /// Foreground color drawn on secondary background.
  final Color onSecondary;

  /// Glass overlay background.
  final Color glassBackground;

  /// Glass overlay border.
  final Color glassBorder;

  /// Default dark theme color scheme extension.
  static const SWColorsExtension dark = SWColorsExtension(
    primary: SWColors.primary,
    secondary: SWColors.secondary,
    background: SWColors.background,
    surface: SWColors.surface,
    surfaceContainer: SWColors.surfaceContainer,
    surfaceContainerHighest: SWColors.surfaceContainerHighest,
    border: SWColors.border,
    borderActive: SWColors.borderActive,
    online: SWColors.online,
    offline: SWColors.offline,
    lan: SWColors.lan,
    bluetooth: SWColors.bluetooth,
    xp: SWColors.xp,
    victory: SWColors.victory,
    success: SWColors.success,
    danger: SWColors.danger,
    warning: SWColors.warning,
    info: SWColors.info,
    textPrimary: SWColors.textPrimary,
    textSecondary: SWColors.textSecondary,
    textMuted: SWColors.textMuted,
    onPrimary: SWColors.onPrimary,
    onSecondary: SWColors.onSecondary,
    glassBackground: SWColors.glassBackground,
    glassBorder: SWColors.glassBorder,
  );

  /// Light theme color scheme extension (adjusted for a premium game visual
  /// feel).
  static const SWColorsExtension light = SWColorsExtension(
    primary: Color(0xFF4F46E5), // slightly darker purple for contrast
    secondary: Color(0xFF0891B2), // slightly darker cyan
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFE5E7EB),
    surfaceContainerHighest: Color(0xFFD1D5DB),
    border: Color(0xFFE5E7EB),
    borderActive: Color(0xFF6366F1),
    online: SWColors.online,
    offline: SWColors.offline,
    lan: SWColors.lan,
    bluetooth: SWColors.bluetooth,
    xp: SWColors.xp,
    victory: SWColors.victory,
    success: SWColors.success,
    danger: SWColors.danger,
    warning: SWColors.warning,
    info: SWColors.info,
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
    onPrimary: SWColors.onPrimary,
    onSecondary: Color(0xFFFFFFFF),
    glassBackground: Color(0x66FFFFFF),
    glassBorder: Color(0x33000000),
  );

  @override
  SWColorsExtension copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceContainerHighest,
    Color? border,
    Color? borderActive,
    Color? online,
    Color? offline,
    Color? lan,
    Color? bluetooth,
    Color? xp,
    Color? victory,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? onPrimary,
    Color? onSecondary,
    Color? glassBackground,
    Color? glassBorder,
  }) {
    return SWColorsExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      border: border ?? this.border,
      borderActive: borderActive ?? this.borderActive,
      online: online ?? this.online,
      offline: offline ?? this.offline,
      lan: lan ?? this.lan,
      bluetooth: bluetooth ?? this.bluetooth,
      xp: xp ?? this.xp,
      victory: victory ?? this.victory,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  SWColorsExtension lerp(ThemeExtension<SWColorsExtension>? other, double t) {
    if (other is! SWColorsExtension) return this;
    return SWColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      surfaceContainerHighest: Color.lerp(
        surfaceContainerHighest,
        other.surfaceContainerHighest,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      lan: Color.lerp(lan, other.lan, t)!,
      bluetooth: Color.lerp(bluetooth, other.bluetooth, t)!,
      xp: Color.lerp(xp, other.xp, t)!,
      victory: Color.lerp(victory, other.victory, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

/// Theme extension for SWDL gradients.
class SWGradientsExtension extends ThemeExtension<SWGradientsExtension> {
  /// Creates an [SWGradientsExtension].
  const SWGradientsExtension({
    required this.primary,
    required this.victory,
    required this.danger,
    required this.xp,
    required this.season,
    required this.premium,
    required this.radialGlow,
  });

  /// Primary brand gradient.
  final LinearGradient primary;

  /// Victory highlight gradient.
  final LinearGradient victory;

  /// Danger/Alert gradient.
  final LinearGradient danger;

  /// Experience level progression gradient.
  final LinearGradient xp;

  /// Season pass progression gradient.
  final LinearGradient season;

  /// Premium gold gradient.
  final LinearGradient premium;

  /// Radial neon backing glow.
  final RadialGradient radialGlow;

  /// Default dark theme gradients extension.
  static const SWGradientsExtension dark = SWGradientsExtension(
    primary: SWGradients.primary,
    victory: SWGradients.victory,
    danger: SWGradients.danger,
    xp: SWGradients.xp,
    season: SWGradients.season,
    premium: SWGradients.premium,
    radialGlow: SWGradients.radialGlow,
  );

  /// Light theme gradients extension.
  static const SWGradientsExtension light = SWGradientsExtension(
    primary: SWGradients.primary,
    victory: SWGradients.victory,
    danger: SWGradients.danger,
    xp: SWGradients.xp,
    season: SWGradients.season,
    premium: SWGradients.premium,
    radialGlow: RadialGradient(
      colors: [Color(0x1F6366F1), Color(0x00000000)],
      radius: 0.8,
    ),
  );

  @override
  SWGradientsExtension copyWith({
    LinearGradient? primary,
    LinearGradient? victory,
    LinearGradient? danger,
    LinearGradient? xp,
    LinearGradient? season,
    LinearGradient? premium,
    RadialGradient? radialGlow,
  }) {
    return SWGradientsExtension(
      primary: primary ?? this.primary,
      victory: victory ?? this.victory,
      danger: danger ?? this.danger,
      xp: xp ?? this.xp,
      season: season ?? this.season,
      premium: premium ?? this.premium,
      radialGlow: radialGlow ?? this.radialGlow,
    );
  }

  @override
  SWGradientsExtension lerp(
    ThemeExtension<SWGradientsExtension>? other,
    double t,
  ) {
    if (other is! SWGradientsExtension) return this;
    return SWGradientsExtension(
      primary: LinearGradient.lerp(primary, other.primary, t)!,
      victory: LinearGradient.lerp(victory, other.victory, t)!,
      danger: LinearGradient.lerp(danger, other.danger, t)!,
      xp: LinearGradient.lerp(xp, other.xp, t)!,
      season: LinearGradient.lerp(season, other.season, t)!,
      premium: LinearGradient.lerp(premium, other.premium, t)!,
      radialGlow: RadialGradient.lerp(radialGlow, other.radialGlow, t)!,
    );
  }
}

/// Helper typography access class.
class SWTypographyClass {
  /// Ultra-large display title.
  TextStyle get displayXL => SWTypography.displayXL;

  /// Main screen title.
  TextStyle get displayLarge => SWTypography.displayLarge;

  /// Section heading.
  TextStyle get heading => SWTypography.heading;

  /// Default title for list elements.
  TextStyle get title => SWTypography.title;

  /// Standard UI body text.
  TextStyle get body => SWTypography.body;

  /// Micro elements description text.
  TextStyle get caption => SWTypography.caption;

  /// Interactive button text.
  TextStyle get button => SWTypography.button;

  /// Numeric score displays.
  TextStyle get score => SWTypography.score;

  /// Numeric timers / countdowns.
  TextStyle get timer => SWTypography.timer;

  /// HUD metadata labels.
  TextStyle get gameLabel => SWTypography.gameLabel;

  /// Numeric scoreboard listings.
  TextStyle get leaderboardNumber => SWTypography.leaderboardNumber;

  /// Display of the active secret word to draw or guess.
  TextStyle get wordPrompt => SWTypography.wordPrompt;

  /// Active round info counter.
  TextStyle get roundCounter => SWTypography.roundCounter;
}

/// Helper spacing access class.
class SWSpacingClass {
  /// Extra small spacing (4dp).
  double get xs => SWSpacing.xs;

  /// Small spacing (8dp).
  double get sm => SWSpacing.sm;

  /// Medium-small spacing (12dp).
  double get md => SWSpacing.md;

  /// Standard spacing (16dp).
  double get lg => SWSpacing.lg;

  /// Medium-large spacing (20dp).
  double get xl => SWSpacing.xl;

  /// Double extra large spacing (24dp).
  double get xxl => SWSpacing.xxl;

  /// Triple extra large spacing (32dp).
  double get xxxl => SWSpacing.xxxl;

  /// Huge spacing (40dp).
  double get huge => SWSpacing.huge;

  /// Epic spacing (48dp).
  double get epic => SWSpacing.epic;

  /// Massive spacing (64dp).
  double get massive => SWSpacing.massive;

  /// Gigantic spacing (96dp).
  double get gigantic => SWSpacing.gigantic;
}

/// Helper radius access class.
class SWRadiusClass {
  /// Small corner radius (4dp).
  double get sVal => SWRadius.sVal;

  /// Medium corner radius (8dp).
  double get mVal => SWRadius.mVal;

  /// Large corner radius (12dp).
  double get lVal => SWRadius.lVal;

  /// Extra large corner radius (16dp).
  double get xlVal => SWRadius.xlVal;

  /// Double extra large corner radius (24dp).
  double get xxlVal => SWRadius.xxlVal;

  /// Triple extra large corner radius (32dp).
  double get xxxlVal => SWRadius.xxxlVal;

  /// Fully circular corner radius (999dp).
  double get circularVal => SWRadius.circularVal;

  /// Small border radius (4dp).
  BorderRadius get s => SWRadius.s;

  /// Medium border radius (8dp).
  BorderRadius get m => SWRadius.m;

  /// Large border radius (12dp).
  BorderRadius get l => SWRadius.l;

  /// Extra large border radius (16dp).
  BorderRadius get xl => SWRadius.xl;

  /// Double extra large border radius (24dp).
  BorderRadius get xxl => SWRadius.xxl;

  /// Triple extra large border radius (32dp).
  BorderRadius get xxxl => SWRadius.xxxl;

  /// Fully circular border radius (999dp).
  BorderRadius get circular => SWRadius.circular;
}

/// Helper animations access class.
class SWAnimationsClass {
  /// Fast duration (100ms).
  Duration get durationFast => SWAnimations.durationFast;

  /// Medium duration (250ms).
  Duration get durationMedium => SWAnimations.durationMedium;

  /// Slow duration (450ms).
  Duration get durationSlow => SWAnimations.durationSlow;

  /// Page duration (350ms).
  Duration get durationPage => SWAnimations.durationPage;

  /// Dialog duration (300ms).
  Duration get durationDialog => SWAnimations.durationDialog;

  /// Decelerate curve.
  Curve get curveDecelerate => SWAnimations.curveDecelerate;

  /// Overshoot curve.
  Curve get curveOvershoot => SWAnimations.curveOvershoot;

  /// Spring curve.
  Curve get curveSpring => SWAnimations.curveSpring;

  /// Bounce curve.
  Curve get curveBounce => SWAnimations.curveBounce;
}

/// Context extensions to access design language tokens directly.
extension SWThemeBuildContextX on BuildContext {
  /// Retrieves dynamic color tokens for current theme.
  SWColorsExtension get swColors =>
      Theme.of(this).extension<SWColorsExtension>() ?? SWColorsExtension.dark;

  /// Retrieves dynamic gradients for current theme.
  SWGradientsExtension get swGradients =>
      Theme.of(this).extension<SWGradientsExtension>() ??
      SWGradientsExtension.dark;

  /// Access helper to retrieve typography.
  SWTypographyClass get swTypography => SWTypographyClass();

  /// Access helper to retrieve responsive spacing tokens.
  SWSpacingClass get swSpacing => SWSpacingClass();

  /// Access helper to retrieve border radius tokens.
  SWRadiusClass get swRadius => SWRadiusClass();

  /// Access helper to retrieve curves and durations.
  SWAnimationsClass get swAnimations => SWAnimationsClass();
}
