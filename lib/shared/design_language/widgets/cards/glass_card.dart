import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';

/// A premium glassmorphic container utilizing backdrop filter blur.
class SWGlassCard extends StatelessWidget {
  /// Creates an [SWGlassCard].
  const SWGlassCard({
    required this.child,
    super.key,
    this.borderRadius,
    this.padding,
    this.borderWidth,
    this.blur,
  });

  /// The child widget.
  final Widget child;

  /// Custom border radius (defaults to [SWRadius.l]).
  final BorderRadius? borderRadius;

  /// Custom interior padding (defaults to 16dp).
  final EdgeInsetsGeometry? padding;

  /// Custom border outline width.
  final double? borderWidth;

  /// Custom backdrop filter blur radius.
  final double? blur;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final radius = borderRadius ?? SWRadius.l;
    final blurVal = blur ?? SWTokens.blurDefault;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassBackground,
            borderRadius: radius,
            border: Border.all(
              color: colors.glassBorder,
              width: borderWidth ?? SWTokens.borderThin,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
