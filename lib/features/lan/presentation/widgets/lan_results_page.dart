import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/features/lan/providers/lan_providers.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart'
    as gameplay;
import 'package:stroke_wars/shared/design_language/swdl.dart';

class LANResultsPage extends ConsumerWidget {
  const LANResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(lANSessionStateProvider);
    final notifier = ref.watch(lANSessionStateProvider.notifier);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final match = session.currentMatch;
    if (match == null) {
      return const Center(child: SWCircularLoading());
    }

    final players = match.players.toList()
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MATCH COMPLETED',
              textAlign: TextAlign.center,
              style: typography.title.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 26.sp,
                letterSpacing: 2.w,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              'Final Leaderboard Results',
              textAlign: TextAlign.center,
              style: typography.body.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: spacing.xl),

            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Final Scores', style: typography.heading),
                  SizedBox(height: spacing.md),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: players.length,
                    separatorBuilder: (_, __) => Divider(color: colors.border),
                    itemBuilder: (context, index) {
                      final p = players[index];
                      final isWinner = index == 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isWinner
                              ? colors.primary
                              : colors.surfaceContainer,
                          child: Text(
                            '#${index + 1}',
                            style: typography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isWinner
                                  ? Colors.white
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                        title: Text(
                          p.displayName,
                          style: typography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          '${p.totalScore} PTS',
                          style: typography.heading.copyWith(
                            color: isWinner
                                ? colors.secondary
                                : colors.textPrimary,
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xl),

            SWButton(
              text: 'Return to lobby / menu',
              onPressed: () => notifier.controller.leaveRoom(),
              variant: SWButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
