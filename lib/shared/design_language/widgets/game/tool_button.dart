import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/motion/motion_effects.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Interactive tool icon button used inside gameplay toolbar grids.
class SWToolButton extends StatelessWidget {
  /// Creates an [SWToolButton].
  const SWToolButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// The mapped [IconData] to display.
  final IconData icon;

  /// Highlighting toggle.
  final bool isSelected;

  /// Tap callback.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;

    return SWPressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42.r,
        height: 42.r,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 1.5.r,
          ),
        ),
        child: Center(
          child: SWIcon(
            icon,
            color: isSelected ? colors.onPrimary : colors.textPrimary,
            size: 20.r,
          ),
        ),
      ),
    );
  }
}
