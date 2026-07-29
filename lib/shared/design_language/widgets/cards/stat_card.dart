import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/cards/surface_card.dart';

/// A card for displaying player and room gameplay statistics.
class SWStatCard extends StatelessWidget {
  /// Creates an [SWStatCard].
  const SWStatCard({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.valueColor,
  });

  /// The statistic label (e.g. 'WIN RATE').
  final String label;

  /// The statistic value (e.g. '84%', '1,200 XP').
  final String value;

  /// Optional icon associated with the statistic.
  final Widget? icon;

  /// Custom text color for the value field.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return SWSurfaceCard(
      padding: EdgeInsets.all(SWSpacing.md),
      child: Row(
        children: [
          if (icon != null) ...[icon!, SizedBox(width: SWSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: typography.gameLabel.copyWith(
                    color: colors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: SWSpacing.xs),
                Text(
                  value,
                  style: typography.score.copyWith(
                    fontSize: 22.sp,
                    color: valueColor ?? colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
