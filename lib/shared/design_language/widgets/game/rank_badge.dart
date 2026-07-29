import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A badge for displaying competitive player ranking divisions.
class SWRankBadge extends StatelessWidget {
  /// Creates an [SWRankBadge].
  const SWRankBadge({required this.division, required this.level, super.key});

  /// The ranking division (e.g. 'Bronze III', 'Diamond I').
  final String division;

  /// The numeric level.
  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.sm,
        vertical: SWSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: SWRadius.s,
        border: Border.all(color: colors.primary, width: 1.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: colors.primary, size: 14.r),
          SizedBox(width: SWSpacing.xs),
          Text(
            '${division.toUpperCase()} • LVL $level',
            style: typography.gameLabel.copyWith(
              fontSize: 10.sp,
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
