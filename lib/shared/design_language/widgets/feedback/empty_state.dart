import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/buttons/sw_button.dart';

/// A template widget for empty views, lists, or lobby rosters.
class SWEmptyState extends StatelessWidget {
  /// Creates an [SWEmptyState].
  const SWEmptyState({
    required this.title,
    required this.message,
    super.key,
    this.icon = SWIcons.info,
    this.actionLabel,
    this.onActionPressed,
  });

  /// The primary title header.
  final String title;

  /// Explanatory message body.
  final String message;

  /// Visual icon (defaults to [SWIcons.info]).
  final IconData icon;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when action button is pressed.
  final VoidCallback? onActionPressed;

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
                color: colors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: SWIcon(icon, color: colors.textMuted, size: 40.r),
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
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: SWSpacing.xl),
              SWButton(
                onPressed: onActionPressed,
                text: actionLabel,
                variant: SWButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
