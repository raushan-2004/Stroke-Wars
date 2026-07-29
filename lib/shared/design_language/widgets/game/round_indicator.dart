import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// HUD element showing the current game round progress (e.g. Round 2/3).
class SWRoundIndicator extends StatelessWidget {
  /// Creates an [SWRoundIndicator].
  const SWRoundIndicator({
    required this.currentRound,
    required this.maxRounds,
    super.key,
  });

  /// The current active round number.
  final int currentRound;

  /// The total count of rounds.
  final int maxRounds;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: SWRadius.m,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        'ROUND $currentRound/$maxRounds',
        style: typography.roundCounter.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: colors.secondary,
        ),
      ),
    );
  }
}
