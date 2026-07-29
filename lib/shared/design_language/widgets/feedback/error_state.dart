import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/buttons/sw_button.dart';

/// A template widget for network, room join, or general system errors.
class SWErrorState extends StatelessWidget {
  /// Creates an [SWErrorState].
  const SWErrorState({
    required this.title,
    required this.message,
    super.key,
    this.icon = SWIcons.error,
    this.retryLabel = 'Retry',
    this.onRetry,
  });

  /// The error title header.
  final String title;

  /// Explanatory error body.
  final String message;

  /// Display icon (defaults to [SWIcons.error]).
  final IconData icon;

  /// Custom retry button text label.
  final String retryLabel;

  /// Callback when retry button is pressed.
  final VoidCallback? onRetry;

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
            Container(
              padding: EdgeInsets.all(SWSpacing.lg),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
              ),
              child: SWIcon(icon, color: colors.danger, size: 40.r),
            ),
            SizedBox(height: SWSpacing.xl),
            Text(
              title,
              style: typography.heading.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SWSpacing.sm),
            Text(
              message,
              style: typography.body.copyWith(color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: SWSpacing.xl),
              SWButton(
                onPressed: onRetry,
                text: retryLabel,
                variant: SWButtonVariant.danger,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
