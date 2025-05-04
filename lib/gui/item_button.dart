import 'package:flutter/material.dart';
import 'package:hello_world/app_resources.dart';
import 'package:hello_world/engine/game_engine.dart';
import '../engine/item.dart';

class ItemButton extends StatefulWidget {
  final Item item;
  final bool showGlow;

  const ItemButton({super.key, required this.item, required this.showGlow});

  @override
  State<ItemButton> createState() => _ItemButtonState();
}

class _ItemButtonState extends State<ItemButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _glowAnimation;

  bool _showGlow = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = ColorTween(
      begin: ResourceColors.glow.withAlpha((0.1*255).toInt()),
      end: ResourceColors.glow.withAlpha((0.8*255).toInt()),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.item.isNew) {
      _controller.repeat(reverse: true);
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _controller.stop();
            _showGlow = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onPressed() async {
    await widget.item.execute(context);
    if (widget.item.isNew) {
      setState(() {
        GameEngine().markAllItemsAsSeen();
        _controller.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.scale(
          scale: widget.item.isNew ? _scaleAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (widget.item.isNew && !_showGlow) ? ResourceColors.newItemBackground(context): Colors.transparent,
              shape: BoxShape.circle, // <<< Macht die Glow-Fläche rund
              boxShadow:
                  (widget.item.isNew && widget.showGlow && _showGlow)
                      ? [
                        BoxShadow(
                          color: _glowAnimation.value ?? Colors.transparent,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: ClipOval(
              // <<< Damit auch das Icon nicht überlappt
              child: IconButton(
                icon: Image.asset(
                  'assets/story/${widget.item.iconAsset}',
                  width: 24,
                  height: 24,
                ),
                onPressed: _onPressed,
              ),
            ),
          ),
        );
      },
    );
  }
}