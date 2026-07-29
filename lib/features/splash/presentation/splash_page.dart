import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:stroke_wars/shared/design_language/swdl.dart';

/// The initial splash / loading screen shown at app launch.
///
/// Animates the Stroke Wars logo in and then navigates to the Home page
/// after a short delay. Handles all app-readiness checks that should
/// not block the app entry point.
class SplashPage extends ConsumerStatefulWidget {
  /// Creates a [SplashPage].
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SWAnimations.durationSlow,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: SWAnimations.curveDecelerate),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: SWAnimations.curveOvershoot),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        context.goNamed('home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LogoBadge(),
                SizedBox(height: 24.h),
                _AppTitle(),
                SizedBox(height: 8.h),
                _Tagline(),
                SizedBox(height: 64.h),
                const SWCircularLoading(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.w,
      height: 120.w,
      decoration: BoxDecoration(
        gradient: context.swGradients.primary,
        borderRadius: SWRadius.xxl,
        boxShadow: SWShadows.glowPurple,
      ),
      child: SWIcon(Icons.draw_rounded, color: Colors.white, size: 64.w),
    );
  }
}

class _AppTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typography = context.swTypography;

    return ShaderMask(
      shaderCallback: (bounds) =>
          context.swGradients.primary.createShader(bounds),
      child: Text(
        'STROKE WARS',
        style: typography.wordPrompt.copyWith(
          fontSize: 36.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
        ),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typography = context.swTypography;
    final colors = context.swColors;

    return Text(
      'Draw. Guess. Conquer.',
      style: typography.body.copyWith(
        color: colors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}
