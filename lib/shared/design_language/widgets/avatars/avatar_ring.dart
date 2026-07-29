import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/avatars/avatar.dart';

/// Wraps [SWAvatar] inside a glowing level progress ring.
class SWAvatarRing extends StatelessWidget {
  /// Creates an [SWAvatarRing].
  const SWAvatarRing({
    required this.avatar,
    required this.progress,
    super.key,
    this.level,
  });

  /// The player avatar to wrap.
  final SWAvatar avatar;

  /// Progress fraction (0.0 to 1.0) showing current level completion.
  final double progress;

  /// Optional level number to render inside a badge.
  final int? level;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(92, 92), // sized slightly larger than large avatar
          painter: _RingPainter(
            progress: progress,
            ringColor: colors.border,
            activeColor: colors.xp,
          ),
          child: Padding(padding: EdgeInsets.all(6.r), child: avatar),
        ),
        if (level != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: colors.xp,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2.r),
              ),
              constraints: BoxConstraints(minWidth: 20.r, minHeight: 20.r),
              child: Center(
                child: Text(
                  level.toString(),
                  style: typography.caption.copyWith(
                    color: colors.onSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.sp,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.activeColor,
  });

  final double progress;
  final Color ringColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 3.r;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final basePaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.activeColor != activeColor;
  }
}
