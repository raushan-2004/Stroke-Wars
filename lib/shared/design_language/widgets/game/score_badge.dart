import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Small HUD element showing current player score points.
class SWScoreBadge extends StatelessWidget {
  /// Creates an [SWScoreBadge].
  const SWScoreBadge({required this.score, super.key});

  /// The score value.
  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.victory.withValues(alpha: 0.12),
        borderRadius: SWRadius.m,
        border: Border.all(color: colors.victory, width: 1.5.r),
      ),
      child: Text(
        '$score PTS',
        style: typography.gameLabel.copyWith(
          color: colors.victory,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}
