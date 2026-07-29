import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A customizable circular loading spinner aligned with SWDL theme aesthetics.
class SWCircularLoading extends StatelessWidget {
  /// Creates an [SWCircularLoading].
  const SWCircularLoading({super.key, this.size, this.strokeWidth, this.color});

  /// Custom size diameter constraint.
  final double? size;

  /// Custom stroke line width.
  final double? strokeWidth;

  /// Custom spinner color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? context.swColors.primary;
    final sizeVal = size ?? 32.r;

    return Center(
      child: SizedBox(
        width: sizeVal,
        height: sizeVal,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth ?? 3.r,
          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          backgroundColor: activeColor.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

/// A full-screen or full-card loading overlay displaying game-themed visual
/// feedback.
class SWLoading extends StatelessWidget {
  /// Creates an [SWLoading].
  const SWLoading({super.key, this.message = 'Connecting to Battle...'});

  /// The message text to display below the spinner.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(SWSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SWCircularLoading(),
            SizedBox(height: SWSpacing.lg),
            Text(
              message,
              style: typography.gameLabel.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
