import 'package:flutter/material.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart' show SWColors;
import 'package:stroke_wars/shared/design_language/tokens/sw_colors.dart'
    show SWColors;

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_shadows.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_tokens.dart';

/// Standard dark layered card container with soft outline borders.
class SWSurfaceCard extends StatelessWidget {
  /// Creates an [SWSurfaceCard].
  const SWSurfaceCard({
    required this.child,
    super.key,
    this.borderRadius,
    this.padding,
    this.useHighestSurface = false,
    this.showGlow = false,
    this.glowColor,
    this.onTap,
  });

  /// Child widget.
  final Widget child;

  /// Custom corner border radius (defaults to [SWRadius.l]).
  final BorderRadius? borderRadius;

  /// Custom interior padding (defaults to 16dp).
  final EdgeInsetsGeometry? padding;

  /// Whether to use [SWColors.surfaceContainerHighest] instead of
  /// [SWColors.surfaceContainer].
  final bool useHighestSurface;

  /// Toggles decorative neon shadow glows.
  final bool showGlow;

  /// Custom color for the border glow shadow.
  final Color? glowColor;

  /// Optional tap handler callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final radius = borderRadius ?? SWRadius.l;
    final bg = useHighestSurface
        ? colors.surfaceContainerHighest
        : colors.surfaceContainer;

    final shadow = showGlow
        ? [
            BoxShadow(
              color: (glowColor ?? colors.primary).withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            ...SWShadows.soft,
          ]
        : SWShadows.soft;

    Widget container = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: showGlow ? (glowColor ?? colors.primary) : colors.border,
          width: showGlow ? SWTokens.borderMedium : SWTokens.borderThin,
        ),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap != null) {
      container = InkWell(onTap: onTap, borderRadius: radius, child: container);
    }

    return container;
  }
}
