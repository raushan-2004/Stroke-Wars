import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/drawing_canvas.dart';
import 'package:stroke_wars/features/online_gameplay/providers/online_game_providers.dart';
import 'package:stroke_wars/features/online_gameplay/domain/models/online_game_session.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class OnlineGamePage extends ConsumerStatefulWidget {
  const OnlineGamePage({super.key});

  @override
  ConsumerState<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends ConsumerState<OnlineGamePage> {
  final _guessController = TextEditingController();
  BrushType _selectedType = BrushType.classic;
  double _brushSize = 8.0;
  Color _selectedColor = Colors.cyan;

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

  void _submitGuess(OnlineGameSessionStateNotifier notifier) {
    final text = _guessController.text.trim();
    if (text.isEmpty) return;
    notifier.controller.sendGuess(text);
    _guessController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gameSession = ref.watch(onlineGameSessionStateNotifierProvider);
    final notifier = ref.watch(onlineGameSessionStateNotifierProvider.notifier);
    final player = ref.watch(playerServiceProvider);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final match = gameSession.currentMatch;
    if (match == null) {
      return const Center(child: SWCircularLoading());
    }

    final round = gameSession.round;
    final localPlayerId =
        gameSession.onlineSession.player?.id.value ?? 'player';
    final isLocalDrawer = round?.drawerSlotId == localPlayerId;

    final secondsLeft = round?.timerState != null
        ? (round!.timerState!.durationSecs - round.timerState!.elapsedSecs)
        : 60;

    return Container(
      color: colors.background,
      child: Column(
        children: [
          // 1. HUD & NETWORK OVERLAY ROW
          _buildHudRow(context, gameSession, secondsLeft, isLocalDrawer),

          // 2. CANVAS AND CHAT BODY
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drawing Canvas
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DrawingCanvas(
                          playerId: localPlayerId,
                          isReadOnly: !isLocalDrawer,
                          isMoveMode: false,
                        ),
                      ),
                      if (isLocalDrawer)
                        Positioned(
                          bottom: spacing.md.r,
                          left: spacing.md.r,
                          right: spacing.md.r,
                          child: _buildDrawingToolbar(
                            context,
                            notifier.controller.canvasController,
                          ),
                        ),
                    ],
                  ),
                ),

                // Guess panel & Leaderboard
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: colors.border)),
                      color: colors.surface.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: _buildChatFeed(context, notifier)),
                        Divider(color: colors.border, height: 1),
                        if (!isLocalDrawer) _buildGuessInput(context, notifier),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudRow(
    BuildContext context,
    OnlineGameSession session,
    int secondsLeft,
    bool isDrawer,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final overlay = session.networkOverlayState;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md.r,
        vertical: spacing.sm.r,
      ),
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Status/Role badge
            Row(
              children: [
                SWBadge(
                  label: isDrawer ? 'YOU ARE DRAWING' : 'GUESS THE WORD',
                  color: isDrawer ? colors.primary : colors.secondary,
                ),
                SizedBox(width: spacing.md),
                if (isDrawer && session.round?.word != null)
                  Text(
                    'Word: ${session.round!.word!.text}',
                    style: typography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            // Timer
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md.r,
                vertical: spacing.xs.r,
              ),
              decoration: BoxDecoration(
                color: secondsLeft < 10
                    ? colors.danger.withValues(alpha: 0.1)
                    : colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${secondsLeft}s',
                style: typography.heading.copyWith(
                  color: secondsLeft < 10 ? colors.danger : colors.textPrimary,
                ),
              ),
            ),

            // Network Overlay HUD
            Row(
              children: [
                Icon(
                  Icons.wifi_tethering_rounded,
                  size: 16.r,
                  color: colors.textMuted,
                ),
                SizedBox(width: spacing.xs),
                Text(
                  '${overlay.latency.toInt()}ms',
                  style: typography.caption.copyWith(color: colors.textMuted),
                ),
                SizedBox(width: spacing.sm),
                SWBadge(
                  label: overlay.synchronizationStatus,
                  color: overlay.synchronizationStatus == 'synchronized'
                      ? colors.success
                      : colors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingToolbar(
    BuildContext context,
    CanvasController controller,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;

    return SWGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Colors
          ...[Colors.cyan, Colors.pink, Colors.yellow, Colors.white].map((
            color,
          ) {
            final selected = _selectedColor == color;
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
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2.r,
                  ),
                ),
              ),
            );
          }),

          // Eraser
          IconButton(
            icon: Icon(
              Icons.cleaning_services_rounded,
              color: colors.textMuted,
            ),
            onPressed: () {
              controller.clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatFeed(
    BuildContext context,
    OnlineGameSessionStateNotifier notifier,
  ) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final history = notifier.controller.chatHistory;

    return ListView.builder(
      padding: EdgeInsets.all(8.r),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final msg = history[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.r),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${msg.senderName}: ',
                  style: typography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                TextSpan(
                  text: msg.text,
                  style: typography.body.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuessInput(
    BuildContext context,
    OnlineGameSessionStateNotifier notifier,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;

    return Container(
      padding: EdgeInsets.all(spacing.sm.r),
      color: colors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _guessController,
              decoration: InputDecoration(
                hintText: 'Type your guess...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: spacing.md.r),
              ),
              onSubmitted: (_) => _submitGuess(notifier),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: colors.primary,
            onPressed: () => _submitGuess(notifier),
          ),
        ],
      ),
    );
  }
}
