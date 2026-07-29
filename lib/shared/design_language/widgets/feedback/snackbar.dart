import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_shadows.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';

/// Utility class for presenting standard, game-themed SnackBar alerts.
abstract final class SWSnackbar {
  /// Displays a customized floating [SnackBar] overlay.
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final accentColor = isError
        ? colors.danger
        : (isSuccess ? colors.success : colors.primary);

    final icon = isError
        ? SWIcons.error
        : (isSuccess ? SWIcons.check : SWIcons.info);

    final snackbar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.all(SWSpacing.lg),
      content: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SWSpacing.md,
          vertical: SWSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: SWRadius.l,
          border: Border.all(color: colors.border, width: SWTokens.borderThin),
          boxShadow: SWShadows.medium,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SWSpacing.xs),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: SWIcon(icon, color: accentColor, size: 18.r),
            ),
            SizedBox(width: SWSpacing.md),
            Expanded(
              child: Text(
                message,
                style: typography.body.copyWith(color: colors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackbar);
  }
}
