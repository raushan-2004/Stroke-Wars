import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/drawing_canvas.dart';
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';
import 'package:stroke_wars/features/replay/providers/replay_providers.dart';
import 'package:stroke_wars/features/replay/application/replay_controller.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class ReplayPage extends ConsumerStatefulWidget {
  const ReplayPage({super.key, required this.replayId});

  final String replayId;

  @override
  ConsumerState<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends ConsumerState<ReplayPage> {
  double _playbackSpeed = 1.0;

  String _formatTime(int ms) {
    final secTotal = ms ~/ 1000;
    final min = secTotal ~/ 60;
    final sec = secTotal % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeReplayProvider(widget.replayId));
    final notifier = ref.watch(activeReplayProvider(widget.replayId).notifier);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text('Replay Viewer', style: typography.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: colors.background,
        child: activeAsync.when(
          loading: () => const Center(child: SWCircularLoading()),
          error: (err, stack) => Center(
            child: Padding(
              padding: EdgeInsets.all(spacing.lg.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64.r,
                    color: colors.danger,
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    'Failed to load replay: $err',
                    style: typography.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (session) {
            final controller = notifier.controller;
            if (controller == null) {
              return const Center(child: SWCircularLoading());
            }

            final currentMs = session.currentFrame;
            final totalMs = session.duration.inMilliseconds;
            final isPlaying = session.playbackState == PlaybackState.playing;

            return Column(
              children: [
                // 1. TOP METADATA BAR
                _buildMetadataHeader(context, session),

                // 2. CANVAS & CHAT SIDEBAR PANEL
                Expanded(
                  child: Row(
                    children: [
                      // Canvas & Timeline Slider
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.all(spacing.md.r),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colors.border),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: DrawingCanvas(
                                    playerId: 'replay',
                                    isReadOnly: true,
                                    isMoveMode: false,
                                  ),
                                ),
                              ),
                            ),

                            // Timeline Controls (Slider & Ticks)
                            _buildTimelineSlider(
                              context,
                              controller,
                              session,
                              currentMs,
                              totalMs,
                            ),
                          ],
                        ),
                      ),

                      // Scoreboard & Replay Chat Sidebar
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: colors.border),
                            ),
                            color: colors.surface.withValues(alpha: 0.5),
                          ),
                          child: Column(
                            children: [
                              // Players & Scores
                              Expanded(
                                flex: 1,
                                child: _buildPlayerScoresList(context, session),
                              ),
                              Divider(color: colors.border, height: 1),
                              // Replay Chat Log
                              Expanded(
                                flex: 2,
                                child: _buildChatFeed(context, controller),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. BOTTOM CONTROL BAR
                _buildPlaybackControlBar(
                  context,
                  controller,
                  session,
                  isPlaying,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetadataHeader(BuildContext context, ReplaySession session) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Container(
      padding: EdgeInsets.all(spacing.md.r),
      color: colors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu_rounded,
                color: colors.primary,
                size: 24.r,
              ),
              SizedBox(width: spacing.sm),
              Text(
                'Replay Match ID: ${session.replayId}',
                style: typography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SWBadge(
            label: session.metadata.gameMode.toUpperCase(),
            color: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSlider(
    BuildContext context,
    ReplayController controller,
    ReplaySession session,
    int currentMs,
    int totalMs,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Column(
      children: [
        // Slider & Ticks Container
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md.r),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.r,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
                  activeTrackColor: colors.primary,
                  inactiveTrackColor: colors.border,
                  thumbColor: colors.primary,
                ),
                child: Slider(
                  value: currentMs.toDouble().clamp(0.0, totalMs.toDouble()),
                  min: 0.0,
                  max: totalMs.toDouble() > 0 ? totalMs.toDouble() : 1.0,
                  onChanged: (val) {
                    controller.seekTo(val.toInt());
                  },
                ),
              ),

              // Round Bookmarks / Markers overlaid on the timeline
              IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth - 32.r;
                    if (width <= 0) return const SizedBox();

                    return Stack(
                      children: session.bookmarks.map((bm) {
                        final ratio = bm.timestampOffsetMs / totalMs;
                        final pos = ratio * width;

                        return Positioned(
                          left: 16.r + pos,
                          child: Container(
                            width: 6.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Time indicator row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg.r,
            vertical: spacing.xs.r,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(currentMs),
                style: typography.caption.copyWith(color: colors.primary),
              ),
              Text(
                _formatTime(totalMs),
                style: typography.caption.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScoresList(BuildContext context, ReplaySession session) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(spacing.sm.r),
          child: Text(
            'Player Scores',
            style: typography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: session.metadata.finalScores.length,
            itemBuilder: (context, index) {
              final key = session.metadata.finalScores.keys.elementAt(index);
              final val = session.metadata.finalScores[key]!;

              return ListTile(
                dense: true,
                title: Text(
                  key,
                  style: typography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  '$val XP',
                  style: typography.caption.copyWith(color: colors.primary),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatFeed(BuildContext context, ReplayController controller) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final history = controller.chatHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(spacing.sm.r),
          child: Text(
            'Replay Chat',
            style: typography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: spacing.sm.r),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final msg = history[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.r),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${msg['senderName']}: ',
                        style: typography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      TextSpan(
                        text: msg['text'] as String,
                        style: typography.caption.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControlBar(
    BuildContext context,
    ReplayController controller,
    ReplaySession session,
    bool isPlaying,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Container(
      color: colors.surface,
      padding: EdgeInsets.all(spacing.md.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Speed controller
          DropdownButton<double>(
            value: _playbackSpeed,
            dropdownColor: colors.surface,
            style: typography.body.copyWith(color: colors.textPrimary),
            underline: const SizedBox(),
            items: [0.5, 1.0, 1.5, 2.0, 4.0].map((s) {
              return DropdownMenuItem<double>(value: s, child: Text('${s}x'));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _playbackSpeed = val);
                controller.setSpeed(val);
              }
            },
          ),

          // Timeline Step backward
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: () => controller.stepBackward(),
          ),

          // Play / Pause
          IconButton(
            iconSize: 42.r,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
            ),
            color: colors.primary,
            onPressed: () {
              if (isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            },
          ),

          // Step forward
          IconButton(
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: () => controller.stepForward(),
          ),

          // Restart
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            onPressed: () => controller.restart(),
          ),
        ],
      ),
    );
  }
}
