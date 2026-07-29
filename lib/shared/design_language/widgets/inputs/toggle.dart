import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart' show SWColors;
import 'package:stroke_wars/shared/design_language/tokens/sw_animations.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_colors.dart'
    show SWColors;
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A custom, highly animated toggle switch matching SWDL.
class SWToggle extends StatelessWidget {
  /// Creates an [SWToggle].
  const SWToggle({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
  });

  /// The active selected state.
  final bool value;

  /// Callback emitted when selection state changes.
  final ValueChanged<bool> onChanged;

  /// Highlight color when active (defaults to [SWColors.primary]).
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final accent = activeColor ?? colors.primary;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        toggled: value,
        child: AnimatedContainer(
          duration: SWAnimations.durationMedium,
          curve: Curves.easeInOut,
          width: 52.w,
          height: 28.h,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            color: value ? accent : colors.border,
            borderRadius: SWRadius.circular,
          ),
          child: AnimatedAlign(
            duration: SWAnimations.durationMedium,
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24.h,
              height: 24.h,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
