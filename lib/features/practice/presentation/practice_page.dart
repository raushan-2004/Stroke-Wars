import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/drawing_canvas.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_configuration.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_session.dart';
import 'package:stroke_wars/features/practice/providers/practice_providers.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Fully-featured Practice Mode screen composing canvas, HUD, overlays, and game loop controllers.
class PracticePage extends ConsumerStatefulWidget {
  /// Creates a [PracticePage].
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  // Practice configuration settings (pre-match)
  int _rounds = 3;
  int _botCount = 2;
  WordDifficulty _difficulty = WordDifficulty.easy;
  WordCategory _category = WordCategory.animals;

  // Drawing tools state
  bool _isMoveMode = false;
  BrushType _selectedType = BrushType.classic;
  double _brushSize = 8.0;
  Color _selectedColor = Colors.cyan;

  // Dialog overlay controller states
  bool _showPauseDialog = false;

  @override
  void initState() {
    super.initState();
    // Try to load any previously auto-saved session when opening the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasSaved = ref.read(practiceSessionStateProvider.notifier).controller.loadSavedSession();
      if (hasSaved) {
        SWToast.show(context, 'Recovered auto-saved practice session.');
      }
    });
  }

  void _updateBrushSettings(CanvasController controller) {
    controller.selectBrush(
      BrushSettings(
        type: _selectedType,
        size: _brushSize,
        opacity: 1.0,
        color: _selectedColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(practiceSessionStateProvider);
    final notifier = ref.watch(practiceSessionStateProvider.notifier);

    if (session == null) {
      return _buildLobbyScreen(context, notifier);
    }

    final match = session.currentMatch;
    final state = match.state;

    // Check if match is finished
    if (state is MatchFinishedState) {
      return _buildCompletionScreen(context, session, notifier);
    }

    return AppScaffold(
      useSafeArea: true,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100.h,
            left: -100.w,
            right: -100.w,
            child: Container(
              height: 400.h,
              decoration: BoxDecoration(
                gradient: context.swGradients.radialGlow,
              ),
            ),
          ),

          // Main Interactive Canvas
          Positioned.fill(
            child: DrawingCanvas(
              playerId: notifier.controller.humanPlayerId,
              isReadOnly: state is! DrawingState && state is! GuessingState,
              isMoveMode: _isMoveMode,
            ),
          ),

          // HUD panel
          Positioned(
            top: context.swSpacing.md.r,
            left: context.swSpacing.md.r,
            right: context.swSpacing.md.r,
            child: _buildHUD(context, session),
          ),

          // Word Selection Overlay
          if (state is WordSelectionState)
            Positioned.fill(
              child: _buildWordSelectionOverlay(context, session, notifier),
            ),

          // Scoreboard Overlay (RoundFinished / ScoreboardState)
          if (state is RoundFinishedState)
            Positioned.fill(
              child: _buildScoreboardOverlay(context, session),
            ),

          // Bottom Toolbar (Only active during drawing/guessing phases)
          if (state is DrawingState || state is GuessingState)
            Positioned(
              bottom: context.swSpacing.md.r,
              left: context.swSpacing.md.r,
              right: context.swSpacing.md.r,
              child: _buildBottomToolbar(context, notifier),
            ),

          // Pause Overlay Dialog
          if (_showPauseDialog)
            Positioned.fill(
              child: _buildPauseOverlay(context, notifier),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Pre-match Lobby Setup UI
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildLobbyScreen(BuildContext context, PracticeSessionState notifier) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final hasSavedSession = notifier.controller.storage.containsKey('active_practice_session');

    return AppScaffold(
      useSafeArea: true,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PRACTICE LOBBY',
                textAlign: TextAlign.center,
                style: typography.title.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 28.sp,
                  letterSpacing: 2.w,
                ),
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Setup your offline practice match settings',
                textAlign: TextAlign.center,
                style: typography.body.copyWith(color: colors.textMuted),
              ),
              SizedBox(height: spacing.xl),

              SWGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Match Settings', style: typography.heading),
                    SizedBox(height: spacing.md),

                    // Rounds Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rounds', style: typography.body),
                        DropdownButton<int>(
                          value: _rounds,
                          dropdownColor: colors.surfaceContainer,
                          style: typography.body.copyWith(color: colors.textPrimary),
                          onChanged: (val) => setState(() => _rounds = val ?? 3),
                          items: const [
                            DropdownMenuItem(value: 3, child: Text('3 Rounds')),
                            DropdownMenuItem(value: 5, child: Text('5 Rounds')),
                            DropdownMenuItem(value: 10, child: Text('10 Rounds')),
                          ],
                        ),
                      ],
                    ),
                    Divider(color: colors.border),

                    // Bots count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Simulated Guessers', style: typography.body),
                        DropdownButton<int>(
                          value: _botCount,
                          dropdownColor: colors.surfaceContainer,
                          style: typography.body.copyWith(color: colors.textPrimary),
                          onChanged: (val) => setState(() => _botCount = val ?? 2),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 Bot')),
                            DropdownMenuItem(value: 2, child: Text('2 Bots')),
                            DropdownMenuItem(value: 3, child: Text('3 Bots')),
                          ],
                        ),
                      ],
                    ),
                    Divider(color: colors.border),

                    // Difficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Word Difficulty', style: typography.body),
                        DropdownButton<WordDifficulty>(
                          value: _difficulty,
                          dropdownColor: colors.surfaceContainer,
                          style: typography.body.copyWith(color: colors.textPrimary),
                          onChanged: (val) => setState(() => _difficulty = val ?? WordDifficulty.easy),
                          items: WordDifficulty.values
                              .map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase())))
                              .toList(),
                        ),
                      ],
                    ),
                    Divider(color: colors.border),

                    // Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Word Category', style: typography.body),
                        DropdownButton<WordCategory>(
                          value: _category,
                          dropdownColor: colors.surfaceContainer,
                          style: typography.body.copyWith(color: colors.textPrimary),
                          onChanged: (val) => setState(() => _category = val ?? WordCategory.animals),
                          items: WordCategory.values
                              .map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.xl),

              if (hasSavedSession) ...[
                SWButton(
                  text: 'RESUME PREVIOUS PRACTICE',
                  onPressed: () {
                    final success = notifier.controller.loadSavedSession();
                    if (!success) {
                      SWToast.show(context, 'Failed to restore session. Starting new.');
                    }
                  },
                  variant: SWButtonVariant.secondary,
                ),
                SizedBox(height: spacing.md),
              ],

              SWButton(
                text: 'START PRACTICE MODE',
                onPressed: () {
                  final config = PracticeConfiguration(
                    rounds: _rounds,
                    botCount: _botCount,
                    difficulty: _difficulty,
                    categories: [_category],
                    drawTimeSecs: 60,
                    scoreboardTimeSecs: 8,
                  );
                  notifier.controller.startPractice(config);
                },
                variant: SWButtonVariant.primary,
              ),
              SizedBox(height: spacing.md),

              SWButton(
                text: 'BACK TO MENU',
                onPressed: () => context.pop(),
                variant: SWButtonVariant.outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Active HUD Panel
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHUD(BuildContext context, PracticeSession session) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final match = session.currentMatch;
    final currentRoundNum = match.rounds.length;
    final totalRounds = match.configuration.totalRounds;

    // Remaining seconds
    final seconds = session.timerState.durationSecs - session.timerState.elapsedSecs;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back/Pause Button
        IconButton.filled(
          icon: const Icon(Icons.pause_rounded),
          onPressed: () {
            setState(() => _showPauseDialog = true);
            ref.read(practiceSessionStateProvider.notifier).controller.pausePractice();
          },
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainer,
            foregroundColor: colors.primary,
          ),
        ),

        // HUD Info Card
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md.r),
            child: SWGlassCard(
              padding: EdgeInsets.symmetric(horizontal: spacing.md.r, vertical: spacing.xs.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ROUND', style: typography.caption.copyWith(color: colors.textMuted)),
                      Text('$currentRoundNum/$totalRounds', style: typography.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('SCORE', style: typography.caption.copyWith(color: colors.textMuted)),
                      Text('${session.score}', style: typography.body.copyWith(color: colors.secondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (session.currentWord != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('DRAW WORD', style: typography.caption.copyWith(color: colors.textMuted)),
                        Text(
                          session.currentWord!.text.toUpperCase(),
                          style: typography.body.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),

        // Timer
        SWGameTimer(
          seconds: seconds.clamp(0, 300),
          maxSeconds: session.timerState.durationSecs.clamp(1, 300),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Bottom Brush Toolbar & Viewport Control
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBottomToolbar(BuildContext context, PracticeSessionState notifier) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final canvasController = ref.watch(canvasControllerProvider);

    return SWGlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Toggle Zoom/Pan vs Draw
              IconButton.filled(
                icon: Icon(
                  _isMoveMode ? Icons.pan_tool_rounded : Icons.brush_rounded,
                ),
                onPressed: () {
                  setState(() => _isMoveMode = !_isMoveMode);
                },
                style: IconButton.styleFrom(
                  backgroundColor: _isMoveMode ? colors.secondary : colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: spacing.md),

              // Dynamic width slider
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.line_weight_rounded, color: colors.textMuted, size: 16.r),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 2.0,
                        max: 32.0,
                        activeColor: colors.primary,
                        inactiveColor: colors.border,
                        onChanged: (v) {
                          setState(() => _brushSize = v);
                          _updateBrushSettings(canvasController);
                        },
                      ),
                    ),
                    Text('${_brushSize.round()}px', style: typography.caption),
                  ],
                ),
              ),
              SizedBox(width: spacing.md),

              // Undo / Redo
              IconButton(
                icon: const Icon(Icons.undo_rounded),
                onPressed: canvasController.state.canUndo ? () => canvasController.undo() : null,
                color: colors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.redo_rounded),
                onPressed: canvasController.state.canRedo ? () => canvasController.redo() : null,
                color: colors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: canvasController.state.strokes.isNotEmpty ? () => canvasController.clear() : null,
                color: colors.danger,
              ),
            ],
          ),
          SizedBox(height: spacing.md),

          // Brush Type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BrushType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: EdgeInsets.only(right: spacing.sm.r),
                  child: ChoiceChip(
                    label: Text(type.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                        _updateBrushSettings(canvasController);
                      }
                    },
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceContainer,
                    labelStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: spacing.md),

          // Palette Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildColorChip(Colors.cyan, canvasController),
                SizedBox(width: spacing.sm),
                _buildColorChip(Colors.purple, canvasController),
                SizedBox(width: spacing.sm),
                _buildColorChip(Colors.orange, canvasController),
                SizedBox(width: spacing.sm),
                _buildColorChip(Colors.pink, canvasController),
                SizedBox(width: spacing.sm),
                _buildColorChip(Colors.green, canvasController),
                SizedBox(width: spacing.sm),
                _buildColorChip(Colors.yellow, canvasController),
                SizedBox(width: spacing.sm),
                _buildColorChip(Colors.white, canvasController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(Color color, CanvasController controller) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedColor = color);
        _updateBrushSettings(controller);
      },
      child: Container(
        width: 28.r,
        height: 28.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.r,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Overlays (Word Choices, Scoreboard, Pause, Completion)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildWordSelectionOverlay(
      BuildContext context, PracticeSession session, PracticeSessionState notifier) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final options = session.currentRound?.wordOptions ?? [];

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg.r),
          child: SWGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CHOOSE A WORD TO DRAW',
                  textAlign: TextAlign.center,
                  style: typography.heading.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.w,
                  ),
                ),
                SizedBox(height: spacing.lg),
                ...options.map((w) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.md.r),
                    child: InkWell(
                      onTap: () => notifier.controller.chooseWord(w),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: spacing.md.r, vertical: spacing.md.r),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          border: Border.all(color: colors.border),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              w.text.toUpperCase(),
                              style: typography.body.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: spacing.xs.r, vertical: spacing.xs.r),
                              decoration: BoxDecoration(
                                color: colors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                w.difficulty.name.toUpperCase(),
                                style: typography.caption.copyWith(color: colors.secondary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreboardOverlay(BuildContext context, PracticeSession session) {
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final players = session.currentMatch.players.toList()
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg.r),
          child: SWGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ROUND SCOREBOARD',
                  textAlign: TextAlign.center,
                  style: typography.heading.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.w),
                ),
                SizedBox(height: spacing.lg),
                ...players.map((p) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.md.r),
                    child: SWLeaderboardRow(
                      rank: players.indexOf(p) + 1,
                      name: p.displayName,
                      score: p.totalScore,
                    ),
                  );
                }),
                SizedBox(height: spacing.lg),
                Text(
                  'Advancing round shortly...',
                  textAlign: TextAlign.center,
                  style: typography.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context, PracticeSessionState notifier) {
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg.r),
          child: SWGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PRACTICE PAUSED',
                  textAlign: TextAlign.center,
                  style: typography.heading.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: spacing.xl),
                SWButton(
                  text: 'RESUME',
                  onPressed: () {
                    setState(() => _showPauseDialog = false);
                    notifier.controller.resumePractice();
                  },
                  variant: SWButtonVariant.primary,
                ),
                SizedBox(height: spacing.md),
                SWButton(
                  text: 'RESTART MATCH',
                  onPressed: () {
                    setState(() => _showPauseDialog = false);
                    notifier.controller.restartPractice();
                  },
                  variant: SWButtonVariant.primary,
                ),
                SizedBox(height: spacing.md),
                SWButton(
                  text: 'QUIT TO HUB',
                  onPressed: () async {
                    setState(() => _showPauseDialog = false);
                    await notifier.controller.quitPractice();
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  variant: SWButtonVariant.outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(
      BuildContext context, PracticeSession session, PracticeSessionState notifier) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final stats = session.practiceStatistics;

    return AppScaffold(
      useSafeArea: true,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PRACTICE COMPLETE',
                textAlign: TextAlign.center,
                style: typography.title.copyWith(fontWeight: FontWeight.w900, fontSize: 26.sp),
              ),
              SizedBox(height: spacing.lg),

              SWGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Session Summary', style: typography.heading),
                    SizedBox(height: spacing.lg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Score', style: typography.body),
                        Text('${session.score}', style: typography.body.copyWith(fontWeight: FontWeight.bold, color: colors.secondary)),
                      ],
                    ),
                    Divider(color: colors.border),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Strokes Drawn', style: typography.body),
                        Text('${stats.strokeCount}', style: typography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: colors.border),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Avg Stroke Points', style: typography.body),
                        Text(stats.averageStrokeLength.toStringAsFixed(1), style: typography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: colors.border),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Avg Round Time', style: typography.body),
                        Text('${stats.averageRoundDuration.toStringAsFixed(1)}s', style: typography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: colors.border),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Drawing Time', style: typography.body),
                        Text('${stats.drawingDuration.round()}s', style: typography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: colors.border),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pause Count', style: typography.body),
                        Text('${stats.pauseCount}', style: typography.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: colors.border),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Replay Recording', style: typography.body),
                        Text(
                          session.replayMetadata.isNotEmpty ? 'SAVED' : 'DISABLED',
                          style: typography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: session.replayMetadata.isNotEmpty ? colors.success : colors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.xl),

              SWButton(
                text: 'BACK TO MENU',
                onPressed: () async {
                  await notifier.controller.quitPractice();
                  if (context.mounted) {
                    context.pop();
                  }
                },
                variant: SWButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
