import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A game HUD timer display that pulses when time is running low.
class SWGameTimer extends StatefulWidget {
  /// Creates an [SWGameTimer].
  const SWGameTimer({
    required this.seconds,
    required this.maxSeconds,
    super.key,
  });

  /// The active remaining time in seconds.
  final int seconds;

  /// The maximum initial time in seconds.
  final int maxSeconds;

  @override
  State<SWGameTimer> createState() => _SWGameTimerState();
}

class _SWGameTimerState extends State<SWGameTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant SWGameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pulse if time is low and changed
    if (widget.seconds <= 10 && widget.seconds != oldWidget.seconds) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final isLowTime = widget.seconds <= 10;
    final progress = widget.seconds / widget.maxSeconds;

    final timerColor = isLowTime ? colors.danger : colors.secondary;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SWSpacing.md,
          vertical: SWSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: SWRadius.m,
          border: Border.all(
            color: isLowTime ? colors.danger : colors.border,
            width: isLowTime ? 2.r : 1.r,
          ),
          boxShadow: isLowTime
              ? [
                  BoxShadow(
                    color: colors.danger.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, color: timerColor, size: 20.r),
            SizedBox(width: SWSpacing.sm),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 36.r,
                  height: 36.r,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.r,
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    backgroundColor: colors.border,
                  ),
                ),
                Text(
                  widget.seconds.toString(),
                  style: typography.leaderboardNumber.copyWith(
                    color: timerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
