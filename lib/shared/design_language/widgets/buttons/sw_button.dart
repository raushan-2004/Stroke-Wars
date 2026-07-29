import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/motion/motion_effects.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_shadows.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_sizes.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';

/// Button variants supported by SWDL.
enum SWButtonVariant {
  /// Elevated/filled purple brand gradient button.
  primary,

  /// Clean flat surface container background button.
  secondary,

  /// Outlined background-less button for lesser actions.
  outlined,

  /// Bright warning color button for destructive actions.
  danger,

  /// Flat round button for icon-only inputs.
  icon,
}

/// A highly polished, animated, and accessible game button.
///
/// Wraps standard Material responses and applies SWDL micro-interactions.
class SWButton extends StatelessWidget {
  /// Creates an [SWButton].
  const SWButton({
    required this.onPressed,
    super.key,
    this.text,
    this.icon,
    this.variant = SWButtonVariant.primary,
    this.isLoading = false,
    this.enabled = true,
    this.width,
    this.height,
    this.semanticLabel,
  }) : assert(
         variant == SWButtonVariant.icon || text != null,
         'A text label is required for all button variants except icon.',
       );

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Display text label.
  final String? text;

  /// Optional icon to render inside.
  final Widget? icon;

  /// Visual theme style variant.
  final SWButtonVariant variant;

  /// Displays a spinner instead of content.
  final bool isLoading;

  /// Toggles interactive state.
  final bool enabled;

  /// Custom button width constraint.
  final double? width;

  /// Custom button height constraint (defaults to [SWSizes.buttonHeight]).
  final double? height;

  /// Descriptive tag for screen reader accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final isInteractive = enabled && !isLoading && onPressed != null;

    // Resolve color style specs
    final (
      Color bg,
      Color fg,
      BorderSide border,
      List<BoxShadow>? shadow,
      Gradient? gradient,
    ) = switch (variant) {
      SWButtonVariant.primary => (
        Colors.transparent,
        colors.onPrimary,
        BorderSide.none,
        isInteractive ? SWShadows.glowPurple : null,
        isInteractive ? context.swGradients.primary : null,
      ),
      SWButtonVariant.secondary => (
        isInteractive ? colors.surfaceContainer : colors.border,
        isInteractive ? colors.textPrimary : colors.textMuted,
        BorderSide.none,
        null,
        null,
      ),
      SWButtonVariant.outlined => (
        Colors.transparent,
        isInteractive ? colors.primary : colors.textMuted,
        BorderSide(
          color: isInteractive ? colors.primary : colors.border,
          width: SWTokens.borderMedium,
        ),
        null,
        null,
      ),
      SWButtonVariant.danger => (
        Colors.transparent,
        colors.onPrimary,
        BorderSide.none,
        isInteractive ? SWShadows.glowOrange : null,
        isInteractive ? context.swGradients.danger : null,
      ),
      SWButtonVariant.icon => (
        isInteractive ? colors.surfaceContainer : colors.border,
        isInteractive ? colors.primary : colors.textMuted,
        BorderSide.none,
        null,
        null,
      ),
    };

    final buttonHeight =
        height ??
        (variant == SWButtonVariant.icon
            ? SWSizes.buttonHeightSmall
            : SWSizes.buttonHeight);

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20.r,
        width: 20.r,
        child: CircularProgressIndicator(
          strokeWidth: 2.r,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else if (variant == SWButtonVariant.icon) {
      content = icon ?? const SizedBox.shrink();
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, SizedBox(width: 8.w)],
          Flexible(
            child: Text(
              text!,
              style: typography.button.copyWith(color: fg),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Outer decoration
    final Widget buttonDecoration = AnimatedContainer(
      duration: context.swAnimations.durationFast,
      width: width,
      height: buttonHeight,
      alignment: Alignment.center,
      padding: variant == SWButtonVariant.icon
          ? EdgeInsets.all(8.r)
          : EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: gradient == null ? (isInteractive ? bg : colors.border) : null,
        gradient: gradient,
        borderRadius: variant == SWButtonVariant.icon
            ? SWRadius.circular
            : SWRadius.l,
        border: border != BorderSide.none
            ? Border.fromBorderSide(border)
            : null,
        boxShadow: shadow,
      ),
      child: content,
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: semanticLabel ?? text,
      child: SWPressableScale(
        enabled: isInteractive,
        onTap: onPressed,
        child: buttonDecoration,
      ),
    );
  }
}
