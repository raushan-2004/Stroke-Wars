import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/avatars/avatar.dart';
import 'package:stroke_wars/shared/design_language/widgets/cards/surface_card.dart';
import 'package:stroke_wars/shared/design_language/widgets/indicators/badge.dart';

/// A card representing a player in a lobby or room.
class SWPlayerCard extends StatelessWidget {
  /// Creates an [SWPlayerCard].
  const SWPlayerCard({
    required this.name,
    required this.score,
    required this.isHost,
    super.key,
    this.avatarUrl,
    this.isReady = false,
  });

  /// The player's display name.
  final String name;

  /// The player's current score.
  final int score;

  /// Whether the player is the room host.
  final bool isHost;

  /// Optional player avatar image URL.
  final String? avatarUrl;

  /// Whether the player is ready to start the game.
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return SWSurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.sm,
      ),
      child: Row(
        children: [
          SWAvatar(name: name, avatarUrl: avatarUrl, size: SWAvatarSize.small),
          SizedBox(width: SWSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: typography.title.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHost) ...[
                      SizedBox(width: SWSpacing.sm),
                      SWBadge(
                        label: 'HOST',
                        color: colors.primary.withValues(alpha: 0.12),
                        textColor: colors.primary,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '$score PTS',
                  style: typography.gameLabel.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: SWSpacing.md),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SWSpacing.md,
              vertical: SWSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isReady
                  ? colors.success.withValues(alpha: 0.12)
                  : colors.border,
              borderRadius: SWRadius.circular,
            ),
            child: Text(
              isReady ? 'READY' : 'WAITING',
              style: typography.gameLabel.copyWith(
                color: isReady ? colors.success : colors.textMuted,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
