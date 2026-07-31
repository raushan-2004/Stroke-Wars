import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/replay/providers/replay_providers.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class MatchHistoryPage extends ConsumerWidget {
  const MatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryListProvider);
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text('Match History & Replays', style: typography.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text(
                    'Are you sure you want to delete all match history and replays?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(matchHistoryListProvider.notifier).clearAll();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colors.danger,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: colors.background,
        padding: EdgeInsets.all(spacing.md.r),
        child: historyAsync.when(
          loading: () => const Center(child: SWCircularLoading()),
          error: (err, stack) =>
              Center(child: Text('Error: $err', style: typography.body)),
          data: (historyList) {
            if (historyList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64.r,
                      color: colors.textMuted,
                    ),
                    SizedBox(height: spacing.md),
                    Text('No matches recorded yet.', style: typography.body),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final record = historyList[index];
                final dateStr =
                    '${record.playedAt.day}/${record.playedAt.month}/${record.playedAt.year}';
                final min = record.duration ~/ 60;
                final sec = record.duration % 60;

                return Padding(
                  padding: EdgeInsets.only(bottom: spacing.sm.r),
                  child: SWGlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: spacing.md.r,
                        vertical: spacing.xs.r,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.videogame_asset_rounded,
                          color: colors.primary,
                        ),
                      ),
                      title: Text(
                        'Winner: ${record.winner}',
                        style: typography.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Mode: ${record.gameMode.toUpperCase()}  |  Duration: ${min}m ${sec}s  |  $dateStr',
                        style: typography.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.play_circle_fill_rounded,
                          color: colors.primary,
                          size: 36.r,
                        ),
                        onPressed: () {
                          context.push('/replays/${record.matchId}');
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
