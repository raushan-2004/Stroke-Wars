import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';
import 'package:stroke_wars/shared/design_language/widgets/buttons/sw_button.dart';

/// A premium, highly animated game dialog.
abstract final class SWDialog {
  /// Displays a customized game alert dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    VoidCallback? onConfirm,
    String? cancelLabel,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'SWDialog',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: context.swAnimations.durationDialog,
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink(); // unused in general dialog transitions
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scale = Tween<double>(begin: 0.8, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        final opacity = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return ScaleTransition(
          scale: scale,
          child: FadeTransition(
            opacity: opacity,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: SWTokens.blurSubtle,
                sigmaY: SWTokens.blurSubtle,
              ),
              child: AlertDialog(
                backgroundColor: colors.surfaceContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: SWRadius.xl,
                  side: BorderSide(
                    color: colors.border,
                    width: SWTokens.borderThin,
                  ),
                ),
                contentPadding: EdgeInsets.all(SWSpacing.xl),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: typography.heading.copyWith(
                        color: colors.textPrimary,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: SWSpacing.md),
                    Text(
                      message,
                      style: typography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: SWSpacing.xl),
                    Row(
                      children: [
                        if (cancelLabel != null)
                          Expanded(
                            child: SWButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onCancel?.call();
                              },
                              text: cancelLabel,
                              variant: SWButtonVariant.secondary,
                            ),
                          ),
                        if (cancelLabel != null && confirmLabel != null)
                          SizedBox(width: SWSpacing.md),
                        if (confirmLabel != null)
                          Expanded(
                            child: SWButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onConfirm?.call();
                              },
                              text: confirmLabel,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
