import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/competitive/providers/competitive_providers.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class MissionsPage extends ConsumerWidget {
  const MissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyMissions = ref.watch(activeDailyMissionsProvider);
    final economy = ref.watch(economyServiceProvider);
    final progression = ref.watch(activeProgressionProvider);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text('Daily & Weekly Challenges', style: typography.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: colors.background,
        padding: EdgeInsets.all(spacing.md.r),
        child: Column(
          children: [
            // Current stats header
            _buildBalanceHeader(context, progression, economy),

            SizedBox(height: spacing.md.r),

            // Daily challenges header
            _buildSectionTitle(context, 'Daily Missions'),

            Expanded(
              child: ListView.builder(
                itemCount: dailyMissions.length,
                itemBuilder: (context, index) {
                  final mission = dailyMissions[index];
                  final ratio = (mission.currentValue / mission.targetValue)
                      .clamp(0.0, 1.0);

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm.r),
                    child: SWGlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.md.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  mission.title,
                                  style: typography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${mission.currentValue} / ${mission.targetValue}',
                                  style: typography.caption.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.sm.r),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8.r,
                                backgroundColor: colors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.primary,
                                ),
                              ),
                            ),
                            SizedBox(height: spacing.sm.r),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '+${mission.rewardXp} XP  |  +${mission.rewardCurrency} Coins',
                                  style: typography.caption.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                                if (mission.isClaimed)
                                  Text(
                                    'CLAIMED',
                                    style: typography.caption.copyWith(
                                      color: colors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else if (mission.isCompleted)
                                  ElevatedButton(
                                    onPressed: () {
                                      ref
                                          .read(
                                            activeDailyMissionsProvider
                                                .notifier,
                                          )
                                          .claimMissionReward(mission.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: spacing.md.r,
                                      ),
                                    ),
                                    child: const Text('Claim Reward'),
                                  )
                                else
                                  // Simulation helper: increment progress directly
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(
                                            activeDailyMissionsProvider
                                                .notifier,
                                          )
                                          .addProgress(
                                            mission.id.contains('draw')
                                                ? 'draw'
                                                : mission.id.contains('guess')
                                                ? 'guess'
                                                : 'win',
                                          );
                                    },
                                    child: const Text('Simulate 1 Step'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(
    BuildContext context,
    dynamic progression,
    dynamic economy,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return SWGlassCard(
      child: Padding(
        padding: EdgeInsets.all(spacing.md.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'YOUR LEVEL',
                  style: typography.caption.copyWith(color: colors.textMuted),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  'Lvl ${progression.level}',
                  style: typography.heading.copyWith(
                    color: colors.primary,
                    fontSize: 20.sp,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'TOTAL XP',
                  style: typography.caption.copyWith(color: colors.textMuted),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  '${progression.xp} XP',
                  style: typography.heading.copyWith(fontSize: 20.sp),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'COIN BALANCE',
                  style: typography.caption.copyWith(color: colors.textMuted),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  '${economy.coins} Coins',
                  style: typography.heading.copyWith(
                    color: Colors.amber,
                    fontSize: 20.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm.r),
      child: Row(
        children: [
          Container(width: 4.r, height: 16.r, color: colors.primary),
          SizedBox(width: 8.r),
          Text(title, style: typography.heading.copyWith(fontSize: 18.sp)),
        ],
      ),
    );
  }
}
