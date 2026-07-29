import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_animations.dart';

/// A pressable widget that animates its scale when pressed.
///
/// Used to provide standard bouncy physics responses on game buttons.
class SWPressableScale extends StatefulWidget {
  /// Creates a [SWPressableScale] widget.
  const SWPressableScale({
    required this.child,
    super.key,
    this.onTap,
    this.scaleDownTo = 0.95,
    this.enabled = true,
  });

  /// The widget to display inside the pressable wrapper.
  final Widget child;

  /// Optional tap handler callback.
  final VoidCallback? onTap;

  /// Target scale factor when pressed (defaults to 0.95).
  final double scaleDownTo;

  /// Whether tap interactions are active.
  final bool enabled;

  @override
  State<SWPressableScale> createState() => _SWPressableScaleState();
}

class _SWPressableScaleState extends State<SWPressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SWAnimations.durationFast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleDownTo,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null || !widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// A clean fade-in entry animation for game list items and text widgets.
class SWFadeEffect extends StatefulWidget {
  /// Creates a [SWFadeEffect] widget.
  const SWFadeEffect({
    required this.child,
    super.key,
    this.duration = SWAnimations.durationMedium,
    this.delay = Duration.zero,
  });

  /// The child to animate.
  final Widget child;

  /// Duration of the fade transition.
  final Duration duration;

  /// Optional start delay.
  final Duration delay;

  @override
  State<SWFadeEffect> createState() => _SWFadeEffectState();
}

class _SWFadeEffectState extends State<SWFadeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// A clean slide-in entry animation with custom offset metrics.
class SWSlideEffect extends StatefulWidget {
  /// Creates a [SWSlideEffect] widget.
  const SWSlideEffect({
    required this.child,
    super.key,
    this.beginOffset = const Offset(0, 0.25),
    this.duration = SWAnimations.durationMedium,
    this.curve = SWAnimations.curveDecelerate,
    this.delay = Duration.zero,
  });

  /// The child to animate.
  final Widget child;

  /// The starting offset offset position relative to the element size.
  final Offset beginOffset;

  /// Duration of the slide transition.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Optional delay before starting the animation.
  final Duration delay;

  @override
  State<SWSlideEffect> createState() => _SWSlideEffectState();
}

class _SWSlideEffectState extends State<SWSlideEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offset = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offset, child: widget.child);
  }
}

/// A springy scale-in transition for indicators, timers, and reward popups.
class SWScaleEffect extends StatefulWidget {
  /// Creates a [SWScaleEffect] widget.
  const SWScaleEffect({
    required this.child,
    super.key,
    this.beginScale = 0.0,
    this.duration = SWAnimations.durationMedium,
    this.curve = SWAnimations.curveOvershoot,
    this.delay = Duration.zero,
  });

  /// The child to animate.
  final Widget child;

  /// Starting scale (defaults to 0.0).
  final double beginScale;

  /// Duration of the scale transition.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Optional delay before starting.
  final Duration delay;

  @override
  State<SWScaleEffect> createState() => _SWScaleEffectState();
}

class _SWScaleEffectState extends State<SWScaleEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(
      begin: widget.beginScale,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
