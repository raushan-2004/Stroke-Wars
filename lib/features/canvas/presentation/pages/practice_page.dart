import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/presentation/profile_edit_page.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';
import 'package:stroke_wars/features/canvas/presentation/widgets/drawing_canvas.dart';

/// Practice drawing mode screen demonstrating the Stroke Engine & Canvas Framework.
class PracticePage extends ConsumerStatefulWidget {
  /// Creates a [PracticePage].
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  bool _isMoveMode = false;
  BrushType _selectedType = BrushType.classic;
  double _brushSize = 8.0;
  Color _selectedColor = Colors.cyan;

  @override
  void initState() {
    super.initState();
    // Reset canvas history when entering practice mode to start clean
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canvasControllerProvider).resetHistory();
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
    final player = ref.watch(playerServiceProvider);
    final controller = ref.watch(canvasControllerProvider);
    final renderQueue = ref.watch(renderQueueProvider);

    final colors = context.swColors;
    final spacing = context.swSpacing;

    final playerId = player?.uuid ?? 'practice-bot';

    return AppScaffold(
      useSafeArea: true,
      body: Stack(
        children: [
          // Radial background glow matching SWDL
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

          // Main canvas area
          Positioned.fill(
            child: DrawingCanvas(
              playerId: playerId,
              isReadOnly: false,
              isMoveMode: _isMoveMode,
            ),
          ),

          // Top navigation bar
          Positioned(
            top: spacing.md.r,
            left: spacing.md.r,
            right: spacing.md.r,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainer,
                    foregroundColor: colors.primary,
                  ),
                ),
                Text(
                  'SANDBOX PRACTICE',
                  style: context.swTypography.title.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.w,
                  ),
                ),
                ListenableBuilder(
                  listenable: renderQueue,
                  builder: (context, child) {
                    final canvasState = renderQueue.currentState;
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.undo_rounded),
                          onPressed: canvasState.canUndo
                              ? () => controller.undo()
                              : null,
                          color: colors.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.redo_rounded),
                          onPressed: canvasState.canRedo
                              ? () => controller.redo()
                              : null,
                          color: colors.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_rounded),
                          onPressed: canvasState.strokes.isNotEmpty
                              ? () => controller.clear()
                              : null,
                          color: colors.danger,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom customizable tool panel
          Positioned(
            bottom: spacing.lg.r,
            left: spacing.lg.r,
            right: spacing.lg.r,
            child: SWGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Viewport Mode & Size Slider Row
                  Row(
                    children: [
                      // Viewport Toggle Button
                      IconButton.filled(
                        icon: Icon(
                          _isMoveMode
                              ? Icons.pan_tool_rounded
                              : Icons.brush_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _isMoveMode = !_isMoveMode;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: _isMoveMode
                              ? colors.secondary
                              : colors.primary,
                          foregroundColor: Colors.white,
                        ),
                        tooltip: _isMoveMode
                            ? 'Switch to Pen'
                            : 'Switch to View Move',
                      ),
                      SizedBox(width: spacing.md),
                      // Size slider
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
                                  _updateBrushSettings(controller);
                                },
                              ),
                            ),
                            Text(
                              '${_brushSize.round()}px',
                              style: context.swTypography.caption.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),

                  // Colors Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildColorChip(Colors.cyan),
                        SizedBox(width: spacing.sm),
                        _buildColorChip(Colors.purple),
                        SizedBox(width: spacing.sm),
                        _buildColorChip(Colors.orange),
                        SizedBox(width: spacing.sm),
                        _buildColorChip(Colors.pink),
                        SizedBox(width: spacing.sm),
                        _buildColorChip(Colors.green),
                        SizedBox(width: spacing.sm),
                        _buildColorChip(Colors.yellow),
                        SizedBox(width: spacing.sm),
                        _buildColorChip(Colors.white),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.md),

                  // Brush types selectors
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
                                _updateBrushSettings(controller);
                              }
                            },
                            selectedColor: colors.primary,
                            backgroundColor: colors.surfaceContainer,
                            labelStyle: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedColor = color);
        _updateBrushSettings(ref.read(canvasControllerProvider));
      },
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.r,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8.r,
                    spreadRadius: 1.r,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
