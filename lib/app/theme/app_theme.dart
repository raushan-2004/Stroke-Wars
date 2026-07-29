import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/app/theme/app_colors.dart';
import 'package:stroke_wars/app/theme/app_typography.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

part 'app_theme.g.dart';

/// Helper mapping string accent color names to Flutter [Color] values.
Color getAccentColorValue(String name) {
  return switch (name.toLowerCase()) {
    'cyan' => const Color(0xFF06B6D4),
    'orange' => const Color(0xFFF97316),
    'pink' => const Color(0xFFEC4899),
    'green' => const Color(0xFF10B981),
    'gold' => const Color(0xFFEAB308),
    'purple' => const Color(0xFF8B5CF6),
    _ => const Color(0xFF8B5CF6),
  };
}

/// The central theme definition for Stroke Wars.
///
/// Provides both light and dark [ThemeData] instances using Material 3.
abstract final class AppTheme {
  /// Light theme definition.
  static ThemeData get lightTheme =>
      buildTheme(brightness: Brightness.light, accentName: 'purple');

  /// Dark theme definition.
  static ThemeData get darkTheme =>
      buildTheme(brightness: Brightness.dark, accentName: 'purple');

  /// Builds [ThemeData] dynamically with custom accent colors.
  static ThemeData buildTheme({
    required Brightness brightness,
    required String accentName,
  }) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final primaryColor = getAccentColorValue(accentName);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceContainerHighest: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
      inversePrimary: colors.inversePrimary,
    );

    final baseColorsExtension = isDark
        ? SWColorsExtension.dark
        : SWColorsExtension.light;
    final customColorsExtension = baseColorsExtension.copyWith(
      primary: primaryColor,
      borderActive: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: AppTypography.buildTextTheme(colorScheme),
      scaffoldBackgroundColor: colors.background,
      extensions: [
        customColorsExtension,
        isDark ? SWGradientsExtension.dark : SWGradientsExtension.light,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.onSurface),
        titleTextStyle: AppTypography.buildTextTheme(colorScheme).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Riverpod provider for light theme config dynamically synced with settings.
@riverpod
ThemeData lightTheme(LightThemeRef ref) {
  final settings = ref.watch(playerSettingsProvider);
  return AppTheme.buildTheme(
    brightness: Brightness.light,
    accentName: settings.accentColor,
  );
}

/// Riverpod provider for dark theme config dynamically synced with settings.
@riverpod
ThemeData darkTheme(DarkThemeRef ref) {
  final settings = ref.watch(playerSettingsProvider);
  return AppTheme.buildTheme(
    brightness: Brightness.dark,
    accentName: settings.accentColor,
  );
}
