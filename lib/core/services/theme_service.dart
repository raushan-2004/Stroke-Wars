import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/core/constants/app_constants.dart';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';

part 'theme_service.g.dart';

/// Manages the active [ThemeMode] with Hive persistence.
///
/// Reads the stored preference on startup and exposes a reactive stream
/// that drives [MaterialApp.themeMode].
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final settings = ref.watch(playerSettingsProvider);
    return _themeFromString(settings.themeMode);
  }

  /// Switches to the specified [ThemeMode] and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final playerService = ref.read(playerServiceProvider.notifier);
    final player = ref.read(playerServiceProvider);

    if (player != null) {
      final updatedPlayer = player.copyWith(
        settings: player.settings.copyWith(themeMode: _themeToString(mode)),
        cosmetics: player.cosmetics.copyWith(theme: _themeToString(mode)),
      );
      await playerService.updatePlayer(updatedPlayer);
    } else {
      // Direct storage update when player is not yet constructed (first launch setup flow)
      final storage = ref.read(storageServiceProvider);
      await storage.put(AppConstants.themePreferenceKey, _themeToString(mode));
    }
    AppLogger.instance.info('Theme mode changed to: $mode');
  }

  /// Cycles through light → dark → system.
  Future<void> cycleTheme() async {
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setThemeMode(next);
  }

  ThemeMode _themeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _themeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}

/// Convenience provider that exposes the current [ThemeMode].
@riverpod
ThemeMode themeMode(ThemeModeRef ref) {
  return ref.watch(themeModeNotifierProvider);
}
