import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Reusable section title header supporting accessory actions.
class SWSectionHeader extends StatelessWidget {
  /// Creates an [SWSectionHeader].
  const SWSectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onActionPressed,
  });

  /// Section group header title.
  final String title;

  /// Optional action label.
  final String? actionLabel;

  /// Callback when action is pressed.
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: SWSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: typography.gameLabel.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onActionPressed != null)
            GestureDetector(
              onTap: onActionPressed,
              child: Text(
                actionLabel!,
                style: typography.caption.copyWith(
                  color: colors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
