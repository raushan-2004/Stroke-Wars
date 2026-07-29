import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';

/// A custom slidable bottom sheet aligned with SWDL theme aesthetics.
abstract final class SWBottomSheet {
  /// Displays a bottom sheet populated with [child].
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
  }) {
    final colors = context.swColors;

    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: isDismissible,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SWTokens.blurSubtle,
            sigmaY: SWTokens.blurSubtle,
          ),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: SWSpacing.sm),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + SWSpacing.lg,
              left: SWSpacing.lg,
              right: SWSpacing.lg,
              top: SWSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(SWRadius.xxlVal),
                topRight: Radius.circular(SWRadius.xxlVal),
              ),
              border: Border(
                top: BorderSide(
                  color: colors.border,
                  width: SWTokens.borderThin,
                ),
                left: BorderSide(
                  color: colors.border,
                  width: SWTokens.borderThin,
                ),
                right: BorderSide(
                  color: colors.border,
                  width: SWTokens.borderThin,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: SWRadius.circular,
                    ),
                  ),
                ),
                SizedBox(height: SWSpacing.lg),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}
