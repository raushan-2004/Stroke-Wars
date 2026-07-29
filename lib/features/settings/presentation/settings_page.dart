import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stroke_wars/core/services/theme_service.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Application settings page.
///
/// Stage 0: Exposes theme switching and app information.
class SettingsPage extends ConsumerWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = context.swColors;

    return AppScaffold(
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
          SizedBox(height: context.swSpacing.lg),
          const SWSectionHeader(title: 'About'),
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
}
