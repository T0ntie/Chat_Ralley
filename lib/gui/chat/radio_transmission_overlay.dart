import 'package:flutter/material.dart';

class RadioTransmissionOverlay extends StatelessWidget {
  final String partialText;
  const RadioTransmissionOverlay({super.key, required this.partialText});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha((0.6 * 255).toInt()),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900.withAlpha((0.85 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.5 * 255).toInt()),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BlinkingLive(),
                const SizedBox(height: 12),
                const Text(
                  "Übertragung aktiv",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.mic, color: Colors.white, size: 48),
                if (partialText.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    partialText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlinkingLive extends StatefulWidget {
  const _BlinkingLive();

  @override
  State<_BlinkingLive> createState() => _BlinkingLiveState();
}

class _BlinkingLiveState extends State<_BlinkingLive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const Text(
        "LIVE",
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
