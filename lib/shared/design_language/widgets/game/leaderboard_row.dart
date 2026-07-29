import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/avatars/avatar.dart';
import 'package:stroke_wars/shared/design_language/widgets/cards/surface_card.dart';

/// A card for displaying players on in-game and post-match leaderboards.
class SWLeaderboardRow extends StatelessWidget {
  /// Creates an [SWLeaderboardRow].
  const SWLeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    super.key,
    this.avatarUrl,
  });

  /// The player's rank number (1-indexed).
  final int rank;

  /// The player's display name.
  final String name;

  /// The player's total match score.
  final int score;

  /// Optional avatar remote image URL.
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    // Resolve top rank highlights
    final (Color rankColor, Color borderColor) = switch (rank) {
      1 => (colors.victory, colors.victory),
      2 => (colors.textSecondary, colors.textSecondary.withValues(alpha: 0.5)),
      3 => (colors.xp, colors.xp.withValues(alpha: 0.3)),
      _ => (colors.textMuted, Colors.transparent),
    };

    return SWSurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.sm,
      ),
      showGlow: rank == 1,
      glowColor: rankColor,
      child: Row(
        children: [
          Container(
            width: 32.w,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: typography.leaderboardNumber.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: SWSpacing.sm),
          SWAvatar(name: name, avatarUrl: avatarUrl, size: SWAvatarSize.small),
          SizedBox(width: SWSpacing.md),
          Expanded(
            child: Text(
              name,
              style: typography.title.copyWith(
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            '$score PTS',
            style: typography.score.copyWith(fontSize: 16.sp, color: rankColor),
          ),
        ],
      ),
    );
  }
}
