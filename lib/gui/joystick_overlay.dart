import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class JoystickOverlay extends StatelessWidget {
  final double heading;
  final bool isVisible;
  final void Function(double dx, double dy) onMove;

  const JoystickOverlay({
    super.key,
    required this.isVisible,
    required this.heading,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Positioned(
      bottom: 5,
      left: 5,
      child: Transform.scale(
        scale: 0.5,
        child: Joystick(
          mode: JoystickMode.all,
          stickOffsetCalculator: CircleStickOffsetCalculator(),
          listener: (details) {
            const double step = 0.00005;
            final double headingRadians = heading * (pi / 180);

            final double dx = -details.y;
            final double dy = details.x;

            final double drx =
                dx * cos(headingRadians) - dy * sin(headingRadians);
            final double dry =
                dx * sin(headingRadians) + dy * cos(headingRadians);

            onMove(drx * step, dry * step);
          },
        ),
      ),
    );
  }
}
