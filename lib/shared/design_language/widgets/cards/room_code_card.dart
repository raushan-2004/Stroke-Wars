import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/buttons/sw_button.dart';
import 'package:stroke_wars/shared/design_language/widgets/cards/surface_card.dart';

/// A card for displaying room lobby codes, featuring quick-copy to clipboard.
class SWRoomCodeCard extends StatefulWidget {
  /// Creates an [SWRoomCodeCard].
  const SWRoomCodeCard({required this.roomCode, super.key});

  /// The active lobby room code (e.g. 'X7F2B').
  final String roomCode;

  @override
  State<SWRoomCodeCard> createState() => _SWRoomCodeCardState();
}

class _SWRoomCodeCardState extends State<SWRoomCodeCard> {
  bool _isCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    setState(() => _isCopied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return SWSurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: SWSpacing.md,
        vertical: SWSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LOBBY CODE',
                  style: typography.gameLabel.copyWith(
                    color: colors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  widget.roomCode,
                  style: typography.score.copyWith(
                    fontSize: 24.sp,
                    letterSpacing: 2,
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: SWSpacing.lg),
          SWButton(
            onPressed: _copyToClipboard,
            variant: SWButtonVariant.icon,
            width: 42.w,
            height: 42.w,
            icon: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isCopied
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: SWIcon(
                SWIcons.copy,
                color: colors.primary,
                size: 18.r,
              ),
              secondChild: SWIcon(
                SWIcons.check,
                color: colors.success,
                size: 18.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
