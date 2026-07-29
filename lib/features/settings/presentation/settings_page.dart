import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stroke_wars/app/theme/app_theme.dart';
import 'package:stroke_wars/core/services/theme_service.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/domain/models/player.dart';
import 'package:stroke_wars/features/profile/domain/models/player_settings.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Application settings page.
///
/// Stage 2: Fully integrates with [PlayerSettings] and gameplay settings persistence.
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
      ThemeMode.system => 'System Default',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerServiceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(playerSettingsProvider);
    final colors = context.swColors;

    return AppScaffold(
      useSafeArea: true,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: context.swTypography.heading.copyWith(letterSpacing: 1),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const SWIcon(SWIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.swSpacing.lg,
          vertical: context.swSpacing.md,
        ),
        children: [
          SWSectionHeader(
            title: 'Appearance',
            actionLabel: 'Cycle Theme',
            onActionPressed: () =>
                ref.read(themeModeNotifierProvider.notifier).cycleTheme(),
          ),
          SizedBox(height: context.swSpacing.sm),
          SWListTile(
            title: 'Active Theme Mode',
            subtitle: _themeLabel(themeMode),
            leading: SWIcon(_themeIcon(themeMode), color: colors.primary),
            trailing: const SWIcon(Icons.chevron_right_rounded),
            onTap: () =>
                ref.read(themeModeNotifierProvider.notifier).cycleTheme(),
          ),
          if (player != null) ...[
            SizedBox(height: context.swSpacing.sm),
            SWListTile(
              title: 'Color Accent Palette',
              subtitle: settings.accentColor.toUpperCase(),
              leading: Icon(
                Icons.palette_rounded,
                color: getAccentColorValue(settings.accentColor),
              ),
              trailing: const SWIcon(Icons.chevron_right_rounded),
              onTap: () {
                // Open bottom sheet accent selection
                _showAccentPickerSheet(context, ref, player, settings);
              },
            ),
          ],
          SizedBox(height: context.swSpacing.lg),

          const SWSectionHeader(title: 'Game Control Preferences'),
          SizedBox(height: context.swSpacing.sm),

          // Sound Preference
          SWListTile(
            title: 'Enable Sound Effects',
            subtitle: 'Toggle lobby audio and game play sounds.',
            leading: const SWIcon(Icons.volume_up_rounded),
            trailing: SWToggle(
              value: settings.soundEnabled,
              onChanged: (val) => _updateSettings(
                ref,
                player,
                settings.copyWith(soundEnabled: val),
              ),
            ),
          ),
          SizedBox(height: context.swSpacing.sm),

          // Haptics Preference
          SWListTile(
            title: 'Enable Haptics Vibrations',
            subtitle:
                'Device haptic feedback response on drawer canvas actions.',
            leading: const SWIcon(Icons.vibration_rounded),
            trailing: SWToggle(
              value: settings.hapticsEnabled,
              onChanged: (val) => _updateSettings(
                ref,
                player,
                settings.copyWith(hapticsEnabled: val),
              ),
            ),
          ),
          SizedBox(height: context.swSpacing.lg),

          const SWSectionHeader(title: 'Accessibility & Motion'),
          SizedBox(height: context.swSpacing.sm),

          // Reduce Motion Preference
          SWListTile(
            title: 'Reduce Interface Motion',
            subtitle:
                'Deactivates background screen transitions and layout animations.',
            leading: const SWIcon(Icons.motion_photos_off_rounded),
            trailing: SWToggle(
              value: settings.reduceMotion,
              onChanged: (val) => _updateSettings(
                ref,
                player,
                settings.copyWith(reduceMotion: val),
              ),
            ),
          ),
          SizedBox(height: context.swSpacing.sm),

          // Animation Speed Preference
          SWListTile(
            title: 'Animation Speed Offset',
            subtitle: settings.animationSpeed.toUpperCase(),
            leading: const SWIcon(Icons.speed_rounded),
            trailing: const SWIcon(Icons.chevron_right_rounded),
            onTap: () {
              _showSpeedPickerSheet(context, ref, player, settings);
            },
          ),
          SizedBox(height: context.swSpacing.lg),

          const SWSectionHeader(title: 'About App'),
          SizedBox(height: context.swSpacing.sm),
          const SWListTile(
            title: 'Version',
            subtitle: '1.0.0',
            leading: SWIcon(SWIcons.info),
          ),
          SizedBox(height: context.swSpacing.sm),
          const SWListTile(
            title: 'Build',
            subtitle: '1',
            leading: SWIcon(Icons.code_rounded),
          ),
          SizedBox(height: context.swSpacing.sm),
          SWListTile(
            title: 'Licenses',
            subtitle: 'View third-party software agreements.',
            leading: const SWIcon(Icons.description_outlined),
            trailing: const SWIcon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }

  void _updateSettings(
    WidgetRef ref,
    Player? player,
    PlayerSettings updatedSettings,
  ) {
    if (player != null) {
      final updatedPlayer = player.copyWith(
        settings: updatedSettings,
        cosmetics: player.cosmetics.copyWith(
          accentColor: updatedSettings.accentColor,
        ),
      );
      ref.read(playerServiceProvider.notifier).updatePlayer(updatedPlayer);
    }
  }

  void _showAccentPickerSheet(
    BuildContext context,
    WidgetRef ref,
    Player? player,
    PlayerSettings settings,
  ) {
    final accents = ['purple', 'cyan', 'orange', 'pink', 'green', 'gold'];

    SWBottomSheet.show<void>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SELECT ACCENT COLOR',
            style: context.swTypography.title.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.swSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: context.swSpacing.md,
            runSpacing: context.swSpacing.md,
            children: accents.map((accent) {
              final color = getAccentColorValue(accent);
              final isSelected = settings.accentColor == accent;

              return SWPressableScale(
                onTap: () {
                  _updateSettings(
                    ref,
                    player,
                    settings.copyWith(accentColor: accent),
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? context.swColors.textPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: context.swSpacing.lg),
        ],
      ),
    );
  }

  void _showSpeedPickerSheet(
    BuildContext context,
    WidgetRef ref,
    Player? player,
    PlayerSettings settings,
  ) {
    final speeds = ['fast', 'medium', 'slow'];

    SWBottomSheet.show<void>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SELECT ANIMATION SPEED',
            style: context.swTypography.title.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.swSpacing.md),
          ...speeds.map((speed) {
            final isSelected = settings.animationSpeed == speed;
            return SWListTile(
              title: speed.toUpperCase(),
              subtitle: 'Speed modifier for design transitions.',
              leading: Icon(
                Icons.speed_rounded,
                color: isSelected ? context.swColors.primary : null,
              ),
              onTap: () {
                _updateSettings(
                  ref,
                  player,
                  settings.copyWith(animationSpeed: speed),
                );
                Navigator.pop(context);
              },
            );
          }),
          SizedBox(height: context.swSpacing.lg),
        ],
      ),
    );
  }
}
