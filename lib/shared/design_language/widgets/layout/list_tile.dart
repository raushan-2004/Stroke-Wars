import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/motion/motion_effects.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Reusable list tile component matching the game aesthetics.
class SWListTile extends StatelessWidget {
  /// Creates an [SWListTile].
  const SWListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  /// The primary title text.
  final String title;

  /// Optional sub-title description text.
  final String? subtitle;

  /// Optional prefix icon or widget.
  final Widget? leading;

  /// Optional suffix icon or widget.
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    Widget tile = Container(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: SWRadius.l,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: SWSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: typography.title.copyWith(color: colors.textPrimary),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: typography.caption.copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: SWSpacing.md), trailing!],
        ],
      ),
    );

    if (onTap != null) {
      tile = SWPressableScale(onTap: onTap, child: tile);
    }

    return tile;
  }
}
