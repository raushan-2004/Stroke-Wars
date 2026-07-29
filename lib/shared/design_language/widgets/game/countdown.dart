import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Pre-match countdown overlay widget (e.g. 3, 2, 1, START!).
class SWCountdown extends StatefulWidget {
  /// Creates an [SWCountdown].
  const SWCountdown({required this.number, super.key});

  /// The active number/state to animate (0 represents 'START!').
  final int number;

  @override
  State<SWCountdown> createState() => _SWCountdownState();
}

class _SWCountdownState extends State<SWCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SWCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.number != oldWidget.number) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final isStart = widget.number <= 0;
    final text = isStart ? 'DRAW!' : widget.number.toString();
    final textColor = isStart ? colors.primary : colors.xp;

    return Center(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Text(
            text,
            style: typography.timer.copyWith(
              fontSize: 100.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
              shadows: [
                BoxShadow(
                  color: textColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
