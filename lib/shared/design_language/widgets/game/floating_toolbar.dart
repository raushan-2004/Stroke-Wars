import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_shadows.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Floating container for canvas drawing utilities and HUD controllers.
class SWFloatingToolbar extends StatelessWidget {
  /// Creates an [SWFloatingToolbar].
  const SWFloatingToolbar({required this.children, super.key, this.padding});

  /// The list of items aligned horizontally inside the panel.
  final List<Widget> children;

  /// Custom padding metrics.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;

    return Container(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: SWSpacing.md,
            vertical: SWSpacing.sm,
          ),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: SWRadius.xl,
        border: Border.all(color: colors.border),
        boxShadow: SWShadows.medium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
