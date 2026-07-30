import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/drawing_canvas.dart';
import 'package:stroke_wars/features/lan/providers/lan_providers.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart'
    as gameplay;
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class LANGamePage extends ConsumerStatefulWidget {
  const LANGamePage({super.key});

  @override
  ConsumerState<LANGamePage> createState() => _LANGamePageState();
}

class _LANGamePageState extends ConsumerState<LANGamePage> {
  final _guessController = TextEditingController();
  bool _isMoveMode = false;
  BrushType _selectedType = BrushType.classic;
  double _brushSize = 8.0;
  Color _selectedColor = Colors.cyan;
  bool _showPauseDialog = false;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
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

  void _submitGuess(LANSessionState notifier, String playerId) {
    final text = _guessController.text.trim();
    if (text.isEmpty) return;
    notifier.controller.sendGuess(text, playerId);
    _guessController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(lANSessionStateProvider);
    final notifier = ref.watch(lANSessionStateProvider.notifier);
    final player = ref.watch(playerServiceProvider);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final match = session.currentMatch;
    if (match == null) {
      return const Center(child: SWCircularLoading());
    }

    final state = match.state;
    final round = match.currentRound;

    final isHost = match.hostId == 'host' || match.hostId == player?.uuid;
    final localPlayerId = isHost ? 'host' : player?.uuid ?? 'guest';
    final isLocalDrawer = round?.drawerSlotId == localPlayerId;
    final isDrawingOrGuessing = state is DrawingState || state is GuessingState;

    final seconds = round?.timerState != null
        ? (round!.timerState!.durationSecs - round.timerState!.elapsedSecs)
        : 0;

    return AppScaffold(
      useSafeArea: true,
      body: Stack(
        children: [
          // Radial Glow
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

          // Main Interactive Canvas (Only drawer can write, others observe)
          Positioned.fill(
            child: DrawingCanvas(
              playerId: localPlayerId,
              isReadOnly: !isLocalDrawer || !isDrawingOrGuessing,
              isMoveMode: _isMoveMode,
            ),
          ),

          // HUD Panel
          Positioned(
            top: spacing.md.r,
            left: spacing.md.r,
            right: spacing.md.r,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.pause_rounded),
                  onPressed: isHost
                      ? () => setState(() => _showPauseDialog = true)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainer,
                    foregroundColor: colors.primary,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.md.r),
                    child: SWGlassCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.md.r,
                        vertical: spacing.xs.r,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ROUND',
                                style: typography.caption.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                              Text(
                                '${match.rounds.length}/${match.configuration.totalRounds}',
                                style: typography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (round?.word != null && isLocalDrawer)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DRAW WORD',
                                  style: typography.caption.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                                Text(
                                  round!.word!.text.toUpperCase(),
                                  style: typography.body.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (round?.word != null && !isLocalDrawer)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DRAWER',
                                  style: typography.caption.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                                Text(
                                  round!.drawerSlotId == 'host'
                                      ? 'Host'
                                      : 'Peer',
                                  style: typography.body.copyWith(
                                    color: colors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SWGameTimer(
                  seconds: seconds.clamp(0, 300),
                  maxSeconds:
                      round?.timerState?.durationSecs.clamp(1, 300) ?? 60,
                ),
              ],
            ),
          ),

          // Bottom Controls: Brush Toolbar (For Drawer)
          if (isLocalDrawer && isDrawingOrGuessing)
            Positioned(
              bottom: spacing.md.r,
              left: spacing.md.r,
              right: spacing.md.r,
              child: _buildBrushToolbar(context, notifier),
            ),

          // Bottom Controls: Guess Input Bar (For Guessers)
          if (!isLocalDrawer && isDrawingOrGuessing)
            Positioned(
              bottom: spacing.md.r,
              left: spacing.md.r,
              right: spacing.md.r,
              child: SWGlassCard(
                padding: EdgeInsets.all(spacing.sm.r),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _guessController,
                        onSubmitted: (_) =>
                            _submitGuess(notifier, localPlayerId),
                        decoration: InputDecoration(
                          hintText: 'Type your guess here...',
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: () => _submitGuess(notifier, localPlayerId),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Word Selection Overlay
          if (state is WordSelectionState && isLocalDrawer)
            Positioned.fill(
              child: _buildWordSelectionOverlay(
                context,
                session,
                notifier,
                localPlayerId,
              ),
            ),

          if (state is WordSelectionState && !isLocalDrawer)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SWCircularLoading(),
                      SizedBox(height: spacing.md),
                      Text(
                        'Drawer is choosing a word...',
                        style: typography.heading.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Scoreboard Overlay
          if (state is RoundFinishedState || state is ScoreboardState)
            Positioned.fill(child: _buildScoreboardOverlay(context, match)),

          // Pause Overlay Dialog
          if (_showPauseDialog)
            Positioned.fill(child: _buildPauseOverlay(context, notifier)),
        ],
      ),
    );
  }

  Widget _buildBrushToolbar(BuildContext context, LANSessionState notifier) {
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
              IconButton.filled(
                icon: Icon(
                  _isMoveMode ? Icons.pan_tool_rounded : Icons.brush_rounded,
                ),
                onPressed: () => setState(() => _isMoveMode = !_isMoveMode),
                style: IconButton.styleFrom(
                  backgroundColor: _isMoveMode
                      ? colors.secondary
                      : colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.line_weight_rounded,
                      color: colors.textMuted,
                      size: 16.r,
                    ),
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
              IconButton(
                icon: const Icon(Icons.undo_rounded),
                onPressed: canvasController.state.canUndo
                    ? () {
                        canvasController.undo();
                        notifier.controller.sendDrawingEvent(
                          const UndoPerformed(),
                        );
                      }
                    : null,
                color: colors.primary,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: canvasController.state.strokes.isNotEmpty
                    ? () {
                        canvasController.clear();
                        notifier.controller.sendDrawingEvent(
                          const CanvasCleared(),
                        );
                      }
                    : null,
                color: colors.danger,
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
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
        width: 26.r,
        height: 26.r,
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

  Widget _buildWordSelectionOverlay(
    BuildContext context,
    LANSession session,
    LANSessionState notifier,
    String localPlayerId,
  ) {
    final spacing = context.swSpacing;
    final colors = context.swColors;
    final typography = context.swTypography;
    final options = session.currentMatch?.currentRound?.wordOptions ?? [];

    return Container(
      color: Colors.black87,
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
                  ),
                ),
                SizedBox(height: spacing.lg),
                ...options.map((w) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.md.r),
                    child: InkWell(
                      onTap: () =>
                          notifier.controller.chooseWord(w, localPlayerId),
                      child: Container(
                        padding: EdgeInsets.all(spacing.md.r),
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
                              style: typography.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                            Text(
                              w.difficulty.name.toUpperCase(),
                              style: typography.caption.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.bold,
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

  Widget _buildScoreboardOverlay(BuildContext context, gameplay.Match match) {
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final players = match.players.toList()
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Container(
      color: Colors.black87,
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
                  style: typography.heading.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: spacing.lg),
                ...players.map((p) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.displayName,
                          style: typography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${p.totalScore} pts',
                          style: typography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildPauseOverlay(BuildContext context, LANSessionState notifier) {
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg.r),
          child: SWGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MATCH PAUSED',
                  textAlign: TextAlign.center,
                  style: typography.heading,
                ),
                SizedBox(height: spacing.md),
                SWButton(
                  text: 'Resume Match',
                  onPressed: () {
                    setState(() => _showPauseDialog = false);
                  },
                  variant: SWButtonVariant.primary,
                ),
                SizedBox(height: spacing.sm),
                SWButton(
                  text: 'Leave Match',
                  onPressed: () {
                    setState(() => _showPauseDialog = false);
                    notifier.controller.leaveRoom();
                  },
                  variant: SWButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
