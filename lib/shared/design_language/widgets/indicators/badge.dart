import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart' show SWColors;
import 'package:stroke_wars/shared/design_language/tokens/sw_colors.dart'
    show SWColors;

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A notification counter or state tag badge.
class SWBadge extends StatelessWidget {
  /// Creates an [SWBadge].
  const SWBadge({required this.label, super.key, this.color, this.textColor});

  /// The label text inside the badge (e.g. 'NEW', '5').
  final String label;

  /// Custom background color (defaults to [SWColors.primary]).
  final Color? color;

  /// Custom text color.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final bg = color ?? colors.primary;
    final fg = textColor ?? colors.onPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.sm,
        vertical: SWSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: SWRadius.circular),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
