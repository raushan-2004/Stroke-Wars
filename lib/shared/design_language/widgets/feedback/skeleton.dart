import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A pulsing skeleton loading widget for content placeholders.
class SWSkeleton extends StatefulWidget {
  /// Creates an [SWSkeleton].
  const SWSkeleton({
    required this.width,
    required this.height,
    super.key,
    this.borderRadius,
    this.isCircular = false,
  });

  /// Placeholder width.
  final double width;

  /// Placeholder height.
  final double height;

  /// Corner border radius (defaults to [SWRadius.m]).
  final BorderRadius? borderRadius;

  /// Sets shape to circular.
  final bool isCircular;

  @override
  State<SWSkeleton> createState() => _SWSkeletonState();
}

class _SWSkeletonState extends State<SWSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colors = context.swColors;
    _colorAnimation = ColorTween(
      begin: colors.surfaceContainer,
      end: colors.surfaceContainerHighest,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isCircular
        ? SWRadius.circular
        : (widget.borderRadius ?? SWRadius.m);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: radius,
          ),
        );
      },
    );
  }
}
