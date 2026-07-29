import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/features/profile/application/player_statistics_service.dart';
import 'package:stroke_wars/features/profile/domain/models/player.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// A premium reusable player summary badge displaying Avatar, XP Ring, Name, and Badge.
class SWPlayerSummary extends ConsumerWidget {
  /// Creates an [SWPlayerSummary] widget.
  const SWPlayerSummary({required this.player, super.key, this.onTap});

  /// The player domain model metadata.
  final Player player;

  /// Optional press interaction.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final spacing = context.swSpacing;

    final stats = player.statistics;
    final statsService = ref.watch(playerStatisticsServiceProvider.notifier);
    final xpProgress = statsService.calculateXpProgress(stats);

    return SWPressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(spacing.sm.r),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: SWRadius.xl,
          border: Border.all(color: colors.border, width: 1.r),
        ),
        child: Row(
          children: [
            SWAvatarRing(
              avatar: SWAvatar(
                name: player.displayName,
                avatarId: player.cosmetics.avatarId,
                avatarFrameId: player.cosmetics.avatarFrame,
                profilePicturePath: player.profilePicturePath,
                size: SWAvatarSize.medium,
              ),
              progress: xpProgress,
              level: stats.level,
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.displayName,
                    style: typography.title.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    player.cosmetics.badge.toUpperCase(),
                    style: typography.caption.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.w,
                      fontSize: 10.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: SWRadius.circular,
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      minHeight: 4.h,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.xp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted,
              size: 24.r,
            ),
          ],
        ),
      ),
    );
  }
}
