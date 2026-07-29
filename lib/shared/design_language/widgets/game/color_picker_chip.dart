import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/motion/motion_effects.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A circular drawing canvas color selector button.
class SWColorPickerChip extends StatelessWidget {
  /// Creates an [SWColorPickerChip].
  const SWColorPickerChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// The drawing brush color to represent.
  final Color color;

  /// Highlighting toggle.
  final bool isSelected;

  /// Callback when color is clicked.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;

    return SWPressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: isSelected ? 3.r : 0.r,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  size: 16.r,
                ),
              )
            : null,
      ),
    );
  }
}
