import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/motion/motion_effects.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Selector component for drawing stroke widths.
class SWBrushSelector extends StatelessWidget {
  /// Creates an [SWBrushSelector].
  const SWBrushSelector({
    required this.strokeWidth,
    required this.selectedWidth,
    required this.onTap,
    super.key,
  });

  /// The stroke thickness value this option represents.
  final double strokeWidth;

  /// The currently active selected thickness.
  final double selectedWidth;

  /// Tap callback.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final isSelected = strokeWidth == selectedWidth;

    return SWPressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 1.5.r,
          ),
        ),
        child: Center(
          child: Container(
            width: strokeWidth.clamp(4.0, 20.0).r,
            height: strokeWidth.clamp(4.0, 20.0).r,
            decoration: BoxDecoration(
              color: isSelected ? colors.onPrimary : colors.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
