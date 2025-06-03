import 'package:flutter/material.dart';

class GlowingAnimatedWrapper extends StatefulWidget {
  final bool animate;
  final Widget child;
  final Duration duration;
  final Color glowColor;

  const GlowingAnimatedWrapper({
    super.key,
    required this.animate,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    required this.glowColor,
  });

  @override
  State<GlowingAnimatedWrapper> createState() => _GlowingAnimatedWrapperState();
}

class _GlowingAnimatedWrapperState extends State<GlowingAnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = ColorTween(
      begin: widget.glowColor.withOpacity(0.1),
      end: widget.glowColor.withOpacity(0.8),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.animate && mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant GlowingAnimatedWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.scale(
          scale: widget.animate ? _scaleAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.animate
                  ? [
                BoxShadow(
                  color: _glowAnimation.value ?? Colors.transparent,
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
                  : [],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
