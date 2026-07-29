import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/motion/motion_effects.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Interactive chip selector for tags, status, or filters.
class SWChip extends StatelessWidget {
  /// Creates an [SWChip].
  const SWChip({
    required this.label,
    super.key,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  /// Chip display text.
  final String label;

  /// Highlight state toggle.
  final bool isSelected;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Optional prefix icon.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final bg = isSelected ? colors.primary : colors.surfaceContainer;
    final fg = isSelected ? colors.onPrimary : colors.textSecondary;
    final border = isSelected ? colors.primary : colors.border;

    Widget chipContent = AnimatedContainer(
      duration: context.swAnimations.durationMedium,
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: SWRadius.circular,
        border: Border.all(color: border, width: 1.5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, SizedBox(width: SWSpacing.sm)],
          Text(
            label,
            style: typography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      chipContent = SWPressableScale(onTap: onTap, child: chipContent);
    }

    return chipContent;
  }
}
