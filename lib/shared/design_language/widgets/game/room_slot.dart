import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A card representation for empty, waiting player slots in a lobby.
class SWRoomSlot extends StatelessWidget {
  /// Creates an [SWRoomSlot].
  const SWRoomSlot({super.key, this.label = 'Waiting for player...'});

  /// The placeholder text label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Container(
      height: 58.h, // matches player card height approximately
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: SWRadius.l,
        border: Border.all(color: colors.border, width: 1.5.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: SWIcon(SWIcons.add, color: colors.textMuted, size: 20.r),
          ),
          SizedBox(width: SWSpacing.md),
          Expanded(
            child: Text(
              label,
              style: typography.body.copyWith(
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
