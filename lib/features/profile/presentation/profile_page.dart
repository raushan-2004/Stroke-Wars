import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:stroke_wars/app/theme/app_theme.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/profile/application/achievement_service.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/application/player_statistics_service.dart';
import 'package:stroke_wars/features/profile/domain/models/player.dart';
import 'package:stroke_wars/features/profile/domain/models/player_statistics.dart';
import 'package:stroke_wars/features/profile/domain/repositories/achievement_repository.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Player profile page displaying gaming statistics, unlocked achievements, and preferences.
class ProfilePage extends ConsumerWidget {
  /// Creates a [ProfilePage].
  const ProfilePage({super.key});

  void _copyUuid(BuildContext context, String uuid) {
    Clipboard.setData(ClipboardData(text: uuid));
    SWToast.show(context, 'Player ID copied to clipboard!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerServiceProvider);
    if (player == null) {
      return const AppScaffold(body: Center(child: SWCircularLoading()));
    }

    final stats = player.statistics;
    final statsService = ref.watch(playerStatisticsServiceProvider.notifier);
    final winRate = statsService.calculateWinRate(stats);
    final avgGuessTime = statsService.calculateAverageGuessTime(stats);
    final xpProgress = statsService.calculateXpProgress(stats);

    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text(
          'PLAYER PROFILE',
          style: typography.heading.copyWith(letterSpacing: 1),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const SWIcon(SWIcons.back),
          onPressed: () => context.goNamed('home'),
        ),
        actions: [
          IconButton(
            icon: const SWIcon(SWIcons.edit),
            onPressed: () => context.pushNamed('profile_edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.swSpacing.lg,
          vertical: context.swSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAvatarCard(context, player, xpProgress),
            SizedBox(height: context.swSpacing.lg),
            _buildStatsSection(context, stats, winRate, avgGuessTime),
            SizedBox(height: context.swSpacing.lg),
            _buildCosmeticsSection(context, player),
            SizedBox(height: context.swSpacing.lg),
            _buildAchievementsSection(context, ref),
            SizedBox(height: context.swSpacing.xl),
            _buildResetButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard(
    BuildContext context,
    Player player,
    double xpProgress,
  ) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return SWGlassCard(
      child: Column(
        children: [
          SWAvatarRing(
            avatar: SWAvatar(
              name: player.displayName,
              avatarId: player.cosmetics.avatarId,
              avatarFrameId: player.cosmetics.avatarFrame,
              profilePicturePath: player.profilePicturePath,
              size: SWAvatarSize.large,
            ),
            progress: xpProgress,
            level: player.statistics.level,
          ),
          SizedBox(height: context.swSpacing.md),
          Text(
            player.displayName,
            style: typography.displayLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (player.username != null) ...[
            SizedBox(height: context.swSpacing.xs),
            Text(
              '@${player.username}',
              style: typography.body.copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.swSpacing.xs),
          Text(
            player.cosmetics.badge.toUpperCase(),
            style: typography.caption.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: context.swSpacing.md),
          GestureDetector(
            onTap: () => _copyUuid(context, player.uuid),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.swSpacing.md,
                vertical: context.swSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: SWRadius.xl,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ID: ${player.uuid.substring(0, 8)}...${player.uuid.substring(player.uuid.length - 4)}',
                    style: typography.caption.copyWith(
                      color: colors.textSecondary,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  SizedBox(width: context.swSpacing.xs),
                  SWIcon(SWIcons.copy, size: 12.r, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    PlayerStatistics stats,
    double winRate,
    double? avgGuessTime,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SWSectionHeader(title: 'Statistics'),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: SWStatCard(
                label: 'Games Played',
                value: stats.gamesPlayed.toString(),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: SWStatCard(
                label: 'Win Rate',
                value: '${winRate.toStringAsFixed(1)}%',
                icon: SWIcon(SWIcons.trophy, color: colors.victory, size: 16.r),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: SWStatCard(
                label: 'Streak',
                value: '${stats.currentWinStreak} wins',
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: SWStatCard(
                label: 'Best Streak',
                value: stats.highestWinStreak.toString(),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: SWStatCard(
                label: 'Avg Guess Time',
                value: avgGuessTime != null
                    ? '${avgGuessTime.toStringAsFixed(1)}s'
                    : '--',
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: SWStatCard(
                label: 'Fastest Guess',
                value: stats.fastestGuess != null
                    ? '${stats.fastestGuess!.toStringAsFixed(1)}s'
                    : '--',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCosmeticsSection(BuildContext context, Player player) {
    final spacing = context.swSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SWSectionHeader(title: 'Cosmetics'),
        SizedBox(height: spacing.sm),
        SWListTile(
          title: 'Favorite Accent Color',
          subtitle: player.settings.accentColor.toUpperCase(),
          leading: Icon(
            Icons.circle,
            color: getAccentColorValue(player.settings.accentColor),
          ),
        ),
        SizedBox(height: spacing.sm),
        SWListTile(
          title: 'Favorite Drawing Tool',
          subtitle: player.cosmetics.favoriteBrush.toUpperCase(),
          leading: const SWIcon(Icons.brush_rounded),
        ),
        SizedBox(height: spacing.sm),
        SWListTile(
          title: 'Visual Theme',
          subtitle: player.settings.themeMode.toUpperCase(),
          leading: Icon(
            player.settings.themeMode == 'dark'
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context, WidgetRef ref) {
    final spacing = context.swSpacing;
    final progressList = ref
        .watch(achievementServiceProvider.notifier)
        .getPlayerAchievementProgress();

    final unlockedCount = progressList.where((p) => p.isUnlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SWSectionHeader(
          title: 'Achievements',
          actionLabel: '$unlockedCount/${progressList.length}',
          onActionPressed: () {},
        ),
        SizedBox(height: spacing.sm),
        if (progressList.isEmpty)
          const SWEmptyState(
            title: 'No Achievements',
            message: 'Start playing games to unlock achievements.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: progressList.length,
            separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
            itemBuilder: (context, index) {
              final progress = progressList[index];
              final repo = ref.read(achievementRepositoryProvider);
              final def = repo.getDefinitions().firstWhere(
                (d) => d.id == progress.achievementId,
              );

              return SWAchievementCard(
                title: def.title,
                description: def.description,
                rewardXP: def.points,
                progress: progress.currentProgress / progress.targetProgress,
              );
            },
          ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    final colors = context.swColors;

    return SWButton(
      onPressed: () {
        SWDialog.show<void>(
          context: context,
          title: 'RESET PROFILE?',
          message:
              'This will delete your name, stats, and achievements permanently. This cannot be undone.',
          confirmLabel: 'DELETE PROFILE',
          onConfirm: () async {
            // Clear settings and database
            await ref.read(playerServiceProvider.notifier).clearPlayer();
            if (context.mounted) {
              context.goNamed('splash');
              SWToast.show(context, 'Player profile deleted successfully.');
            }
          },
          cancelLabel: 'KEEP PROFILE',
        );
      },
      text: 'RESET ALL APP DATA',
      variant: SWButtonVariant.danger,
      icon: SWIcon(Icons.delete_forever_rounded, color: colors.onPrimary),
    );
  }
}
