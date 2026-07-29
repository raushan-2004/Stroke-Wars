import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/core/services/theme_service.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// The official Stroke Wars Design Language (SWDL) Interactive Showcase.
///
/// Serves as a dynamic sandbox/storybook to test and preview all design system
/// tokens, components, and animations.
class HomePage extends ConsumerStatefulWidget {
  /// Creates a [HomePage].
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Input states
  final _textController = TextEditingController();
  bool _toggleVal = false;
  double _xpProgress = 0.65;

  // Game components selection states
  Color _selectedColor = Colors.red;
  double _selectedBrushWidth = 8;
  IconData _selectedTool = SWIcons.brush;

  // Countdown demo state
  int _countdownVal = 3;
  bool _showCountdown = false;

  void _triggerCountdown() {
    setState(() {
      _countdownVal = 3;
      _showCountdown = true;
    });
    _runCountdownTick();
  }

  void _runCountdownTick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdownVal > 0) {
        setState(() => _countdownVal--);
        _runCountdownTick();
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showCountdown = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final themeMode = ref.watch(themeModeProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: Stack(
        children: [
          // Background Glow
          Positioned.fill(child: Container(color: colors.background)),
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

          // Reactive Network Banner
          const Positioned(top: 0, left: 0, right: 0, child: SWNetworkStatus()),

          // Main Scrollable Showcase Contents
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.swSpacing.lg,
                  vertical: context.swSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, themeMode),
                    SizedBox(height: context.swSpacing.xl),

                    // Typography
                    _buildSection('Typography', [
                      Text(
                        'Display XL Title',
                        style: context.swTypography.displayXL,
                      ),
                      Text(
                        'Display Large Heading',
                        style: context.swTypography.displayLarge,
                      ),
                      Text(
                        'Standard Section Heading',
                        style: context.swTypography.heading,
                      ),
                      Text(
                        'List / Card Element Title',
                        style: context.swTypography.title,
                      ),
                      Text(
                        'Standard UI Body Paragraph Text',
                        style: context.swTypography.body,
                      ),
                      Text(
                        'Micro caption descriptive text',
                        style: context.swTypography.caption,
                      ),
                    ]),

                    // Buttons
                    _buildSection('Interactive Buttons', [
                      SWButton(
                        onPressed: () =>
                            SWToast.show(context, 'Primary Clicked!'),
                        text: 'PRIMARY GRADIENT BUTTON',
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      SWButton(
                        onPressed: () => SWSnackbar.show(
                          context,
                          'Secondary action confirmed!',
                        ),
                        text: 'Secondary Action',
                        variant: SWButtonVariant.secondary,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      SWButton(
                        onPressed: () {},
                        text: 'Danger Destructive Action',
                        variant: SWButtonVariant.danger,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      SWButton(
                        onPressed: () {},
                        text: 'Outlined Action Option',
                        variant: SWButtonVariant.outlined,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SWButton(
                            onPressed: () {},
                            text: 'Loading',
                            isLoading: true,
                          ),
                          const SWButton(
                            onPressed: null,
                            text: 'Disabled Button',
                          ),
                        ],
                      ),
                    ]),

                    // Cards
                    _buildSection('Layered Cards', [
                      SWSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard Surface Card',
                              style: context.swTypography.title.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: context.swSpacing.xs),
                            Text(
                              'Soft layered background with '
                              'subtle outline borders.',
                              style: context.swTypography.body,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      SWGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Acrylic Glass Card',
                              style: context.swTypography.title.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: context.swSpacing.xs),
                            Text(
                              'Translucent container featuring '
                              'dynamic backdrop filter blurs.',
                              style: context.swTypography.body.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SWStatCard(
                              label: 'Win Rate',
                              value: '78.5%',
                              icon: SWIcon(
                                SWIcons.trophy,
                                color: colors.victory,
                                size: 24.r,
                              ),
                            ),
                          ),
                          SizedBox(width: context.swSpacing.sm),
                          const Expanded(
                            child: SWRoomCodeCard(roomCode: 'X8F4D'),
                          ),
                        ],
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWAchievementCard(
                        title: 'Perfect Canvas',
                        description:
                            'Win a game with 100% '
                            'correct artist drawing ratings.',
                        rewardXP: 800,
                        progress: 0.7,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWAchievementCard(
                        title: 'Elite Competitor',
                        description: 'Reach Grandmaster rank division.',
                        rewardXP: 2500,
                        isLocked: true,
                      ),
                    ]),

                    // Avatars
                    _buildSection('Player Avatars', [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const SWAvatar(
                            name: 'Alex Johnson',
                            size: SWAvatarSize.small,
                          ),
                          const SWAvatar(name: 'Sarah Connor'),
                          SWAvatarRing(
                            avatar: const SWAvatar(
                              name: 'Bruce Wayne',
                              size: SWAvatarSize.large,
                            ),
                            progress: _xpProgress,
                            level: 24,
                          ),
                        ],
                      ),
                      SizedBox(height: context.swSpacing.md),
                      Slider(
                        value: _xpProgress,
                        onChanged: (v) => setState(() => _xpProgress = v),
                        activeColor: colors.xp,
                        inactiveColor: colors.border,
                      ),
                    ]),

                    // Inputs & Forms
                    _buildSection('Inputs & Selection Controls', [
                      SWTextField(
                        controller: _textController,
                        hintText: 'Enter secret lobby username...',
                        prefixIcon: SWIcon(
                          SWIcons.profile,
                          color: colors.textMuted,
                        ),
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWSearchField(),
                      SizedBox(height: context.swSpacing.sm),
                      SWListTile(
                        title: 'Enable Background Ambient Music',
                        subtitle: 'Toggles lobby soundtrack looping.',
                        leading: SWIcon(
                          SWIcons.settings,
                          color: colors.primary,
                        ),
                        trailing: SWToggle(
                          value: _toggleVal,
                          onChanged: (v) {
                            setState(() => _toggleVal = v);
                            SWToast.show(context, 'Music: ${v ? "ON" : "OFF"}');
                          },
                        ),
                      ),
                    ]),

                    // Feedback overlays
                    _buildSection('Visual Feedback & Popups', [
                      Row(
                        children: [
                          Expanded(
                            child: SWButton(
                              onPressed: () {
                                SWDialog.show<void>(
                                  context: context,
                                  title: 'Quit Match?',
                                  message:
                                      'Leaving the game now will '
                                      'result in automatic point losses.',
                                  confirmLabel: 'QUIT BATTLE',
                                  onConfirm: () =>
                                      SWToast.show(context, 'Match abandoned.'),
                                  cancelLabel: 'RESUME PLAY',
                                );
                              },
                              text: 'Trigger Dialog',
                              variant: SWButtonVariant.outlined,
                            ),
                          ),
                          SizedBox(width: context.swSpacing.sm),
                          Expanded(
                            child: SWButton(
                              onPressed: () {
                                SWBottomSheet.show<void>(
                                  context: context,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'LOBBY PARTICIPANTS',
                                        style: context.swTypography.heading,
                                      ),
                                      SizedBox(height: context.swSpacing.md),
                                      const SWPlayerCard(
                                        name: 'DrawingPro',
                                        score: 1200,
                                        isHost: true,
                                        isReady: true,
                                      ),
                                      SizedBox(height: context.swSpacing.sm),
                                      const SWPlayerCard(
                                        name: 'SketchMaster',
                                        score: 950,
                                        isHost: false,
                                      ),
                                      SizedBox(height: context.swSpacing.lg),
                                      SWButton(
                                        onPressed: () => Navigator.pop(context),
                                        text: 'CLOSE LIST',
                                        variant: SWButtonVariant.secondary,
                                      ),
                                    ],
                                  ),
                                );
                              },
                              text: 'Bottom Sheet',
                              variant: SWButtonVariant.outlined,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SWButton(
                              onPressed: () => SWToast.show(
                                context,
                                'Level Unlocked! +200 XP',
                              ),
                              text: 'Toast Message',
                              variant: SWButtonVariant.outlined,
                            ),
                          ),
                          SizedBox(width: context.swSpacing.sm),
                          Expanded(
                            child: SWButton(
                              onPressed: () => SWSnackbar.show(
                                context,
                                'Connection latency has increased.',
                                isError: true,
                              ),
                              text: 'Error Snackbar',
                              variant: SWButtonVariant.outlined,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.swSpacing.md),
                      const SWSkeleton(width: double.infinity, height: 48),
                    ]),

                    // Game Specific
                    _buildSection('Gameplay HUD & Lobby Elements', [
                      SWButton(
                        onPressed: _triggerCountdown,
                        text: 'LAUNCH COUNTDOWN DEMO',
                      ),
                      SizedBox(height: context.swSpacing.md),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          SWRoundIndicator(currentRound: 2, maxRounds: 3),
                          SWScoreBadge(score: 1450),
                          SWRankBadge(division: 'Gold II', level: 14),
                        ],
                      ),
                      SizedBox(height: context.swSpacing.md),
                      const Center(
                        child: SWGameTimer(seconds: 8, maxSeconds: 80),
                      ),
                      SizedBox(height: context.swSpacing.md),
                      const Center(
                        child: SWWordDisplay(
                          word: 'SPACESHIP',
                          revealedIndices: [0, 1, 4, 8],
                        ),
                      ),
                      SizedBox(height: context.swSpacing.md),
                      const SWPlayerCard(
                        name: 'VibrantDoodler',
                        score: 420,
                        isHost: true,
                        isReady: true,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWRoomSlot(),
                      SizedBox(height: context.swSpacing.lg),
                      SWSectionHeader(
                        title: 'Match Scoreboard',
                        actionLabel: 'View Season History',
                        onActionPressed: () {},
                      ),
                      const SWLeaderboardRow(
                        rank: 1,
                        name: 'CanvasQueen',
                        score: 3200,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWLeaderboardRow(
                        rank: 2,
                        name: 'DoodleLord',
                        score: 2850,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWLeaderboardRow(
                        rank: 3,
                        name: 'SketchGod',
                        score: 1950,
                      ),
                      SizedBox(height: context.swSpacing.sm),
                      const SWLeaderboardRow(
                        rank: 4,
                        name: 'NovicePainter',
                        score: 620,
                      ),
                    ]),

                    // Canvas Toolbar Widgets
                    _buildSection('Canvas Painting Toolbar Controls', [
                      Center(
                        child: SWFloatingToolbar(
                          children: [
                            SWToolButton(
                              icon: SWIcons.brush,
                              isSelected: _selectedTool == SWIcons.brush,
                              onTap: () =>
                                  setState(() => _selectedTool = SWIcons.brush),
                            ),
                            SizedBox(width: context.swSpacing.sm),
                            SWToolButton(
                              icon: SWIcons.eraser,
                              isSelected: _selectedTool == SWIcons.eraser,
                              onTap: () => setState(
                                () => _selectedTool = SWIcons.eraser,
                              ),
                            ),
                            SizedBox(width: context.swSpacing.sm),
                            SWToolButton(
                              icon: SWIcons.undo,
                              isSelected: _selectedTool == SWIcons.undo,
                              onTap: () =>
                                  SWToast.show(context, 'Undo canvas action.'),
                            ),
                            SizedBox(width: context.swSpacing.sm),
                            SWToolButton(
                              icon: SWIcons.clear,
                              isSelected: false,
                              onTap: () =>
                                  SWToast.show(context, 'Canvas cleared.'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.swSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SWBrushSelector(
                            strokeWidth: 4,
                            selectedWidth: _selectedBrushWidth,
                            onTap: () =>
                                setState(() => _selectedBrushWidth = 4.0),
                          ),
                          SizedBox(width: context.swSpacing.md),
                          SWBrushSelector(
                            strokeWidth: 8,
                            selectedWidth: _selectedBrushWidth,
                            onTap: () =>
                                setState(() => _selectedBrushWidth = 8.0),
                          ),
                          SizedBox(width: context.swSpacing.md),
                          SWBrushSelector(
                            strokeWidth: 16,
                            selectedWidth: _selectedBrushWidth,
                            onTap: () =>
                                setState(() => _selectedBrushWidth = 16.0),
                          ),
                        ],
                      ),
                      SizedBox(height: context.swSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SWColorPickerChip(
                            color: Colors.red,
                            isSelected: _selectedColor == Colors.red,
                            onTap: () =>
                                setState(() => _selectedColor = Colors.red),
                          ),
                          SizedBox(width: context.swSpacing.sm),
                          SWColorPickerChip(
                            color: Colors.yellow,
                            isSelected: _selectedColor == Colors.yellow,
                            onTap: () =>
                                setState(() => _selectedColor = Colors.yellow),
                          ),
                          SizedBox(width: context.swSpacing.sm),
                          SWColorPickerChip(
                            color: Colors.green,
                            isSelected: _selectedColor == Colors.green,
                            onTap: () =>
                                setState(() => _selectedColor = Colors.green),
                          ),
                          SizedBox(width: context.swSpacing.sm),
                          SWColorPickerChip(
                            color: Colors.blue,
                            isSelected: _selectedColor == Colors.blue,
                            onTap: () =>
                                setState(() => _selectedColor = Colors.blue),
                          ),
                        ],
                      ),
                    ]),

                    SizedBox(height: context.swSpacing.gigantic),
                  ],
                ),
              ),
            ),
          ),

          // Countdown Full-Screen Overlay
          if (_showCountdown)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.8),
                child: SWCountdown(number: _countdownVal),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeMode themeMode) {
    final colors = context.swColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    context.swGradients.primary.createShader(bounds),
                child: Text(
                  'STROKE WARS',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                'Interactive Component Showcase (SWDL)',
                style: context.swTypography.caption,
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: () {
            ref.read(themeModeNotifierProvider.notifier).cycleTheme();
          },
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
          ),
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainer,
            foregroundColor: colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: context.swSpacing.xl),
        SWSectionHeader(title: title),
        SizedBox(height: context.swSpacing.md),
        ...children,
        Divider(color: context.swColors.border),
      ],
    );
  }
}
