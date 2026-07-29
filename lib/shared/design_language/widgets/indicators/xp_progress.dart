import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_animations.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// An animated progress bar displaying level and XP progression.
class SWXPProgress extends StatelessWidget {
  /// Creates an [SWXPProgress].
  const SWXPProgress({
    required this.progress,
    super.key,
    this.height,
    this.showLabel = true,
  });

  /// The progress ratio (0.0 to 1.0).
  final double progress;

  /// Custom bar height constraint.
  final double? height;

  /// Toggles displaying numerical percentages.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final barHeight = height ?? 8.h;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final activeWidth = maxWidth * progress.clamp(0.0, 1.0);

            return Stack(
              children: [
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: SWRadius.circular,
                  ),
                ),
                AnimatedContainer(
                  duration: SWAnimations.durationSlow,
                  curve: SWAnimations.curveOvershoot,
                  width: activeWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: context.swGradients.xp,
                    borderRadius: SWRadius.circular,
                    boxShadow: [
                      BoxShadow(
                        color: colors.xp.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (showLabel) ...[
          SizedBox(height: SWSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP PROGRESS',
                style: typography.gameLabel.copyWith(
                  fontSize: 10.sp,
                  color: colors.textMuted,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: typography.leaderboardNumber.copyWith(
                  fontSize: 12.sp,
                  color: colors.xp,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
