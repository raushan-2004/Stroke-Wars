import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/cards/surface_card.dart';
import 'package:stroke_wars/shared/design_language/widgets/indicators/xp_progress.dart';

/// Renders a game achievement detail card showing locked/unlocked progress.
class SWAchievementCard extends StatelessWidget {
  /// Creates an [SWAchievementCard].
  const SWAchievementCard({
    required this.title,
    required this.description,
    required this.rewardXP,
    super.key,
    this.progress = 1.0,
    this.isLocked = false,
  });

  /// The achievement title.
  final String title;

  /// Detailed description of how to complete the achievement.
  final String description;

  /// The XP reward value (e.g. 500).
  final int rewardXP;

  /// The completion progress fraction (0.0 to 1.0).
  final double progress;

  /// Flag indicating if the reward is locked.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return SWSurfaceCard(
      useHighestSurface: isLocked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(SWSpacing.sm),
                decoration: BoxDecoration(
                  color: isLocked
                      ? colors.border
                      : colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: SWIcon(
                  isLocked ? SWIcons.trophy : SWIcons.trophy,
                  color: isLocked ? colors.textMuted : colors.victory,
                  size: 20.r,
                ),
              ),
              SizedBox(width: SWSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: typography.title.copyWith(
                        color: isLocked
                            ? colors.textSecondary
                            : colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: typography.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: SWSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+$rewardXP XP',
                    style: typography.gameLabel.copyWith(
                      color: isLocked ? colors.textMuted : colors.xp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (progress < 1.0 && progress > 0.0) ...[
            SizedBox(height: SWSpacing.md),
            SWXPProgress(progress: progress, showLabel: false, height: 6.h),
          ],
        ],
      ),
    );
  }
}
