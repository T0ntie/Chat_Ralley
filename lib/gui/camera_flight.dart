import 'dart:ui';
import 'package:flutter/animation.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:storytrail/gui/game_screen.dart';

class CameraFlight {
  final GameScreenState state;
  final LatLng to;
  final double toZoom;
  final LatLng from;
  final double fromZoom;
  final MapController controller;

  CameraFlight({
    required this.state,
    required this.controller,
    required this.to,
    this.toZoom = 17.0,
  })  : from = controller.camera.center,
        fromZoom = controller.camera.zoom;

  Future<void> animate() async {
    final animator = CameraFlightAnimator(
      vsync: state,
      controller: controller,
    );

    final distanceCalc = const Distance();
    final dist = distanceCalc(from, to);

    if (dist < 100) {
      controller.move(to, toZoom);
      print("📍 Jumped to nearby target");
      return;
    }

    Duration dynamicDuration(double base) {
      final millis = (base + dist / 8).clamp(1200, 5000);
      return Duration(milliseconds: millis.toInt());
    }

    final duration = dynamicDuration(1000);

    // ✈️ Hinflug: sanft mit getrenntem Zoom
    await animator.animateCameraSplitZoom(
      from: from,
      to: to,
      fromZoom: fromZoom,
      toZoom: toZoom,
      duration: duration,
      positionCurve: Curves.easeInOut,
      zoomCurve: Curves.easeOutCubic,
    );

    print("📍 Arrived at target");

    // ⏱️ Verweilen
    await Future.delayed(const Duration(seconds: 1));

    // 🔙 Rückflug: einfache Bewegung zurück
    await animator.animateCamera(
      from: to,
      to: from,
      fromZoom: toZoom,
      toZoom: fromZoom,
      duration: duration,
      curve: Curves.easeInOut,
    );

    print("🔙 Returned to original position");
  }
}

class CameraFlightAnimator {
  final TickerProvider vsync;
  final MapController controller;

  CameraFlightAnimator({
    required this.vsync,
    required this.controller,
  });

  /// Klassische Kamerabewegung mit Position & Zoom gleichzeitig
  Future<void> animateCamera({
    required LatLng from,
    required LatLng to,
    required double fromZoom,
    required double toZoom,
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) async {
    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: curve,
    );

    animation.addListener(() {
      final t = animation.value;
      final lat = lerpDouble(from.latitude, to.latitude, t)!;
      final lng = lerpDouble(from.longitude, to.longitude, t)!;
      final zoom = lerpDouble(fromZoom, toZoom, t)!;
      controller.move(LatLng(lat, lng), zoom);
    });

    await animationController.forward();
    animationController.dispose();
  }

  /// Erweiterte Methode mit separatem Zoom- und Positionsverlauf
  Future<void> animateCameraSplitZoom({
    required LatLng from,
    required LatLng to,
    required double fromZoom,
    required double toZoom,
    required Duration duration,
    Curve positionCurve = Curves.easeInOut,
    Curve zoomCurve = Curves.easeInOut,
  }) async {
    final animationController = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final positionAnimation = CurvedAnimation(
      parent: animationController,
      curve: positionCurve,
    );

    final zoomAnimation = CurvedAnimation(
      parent: animationController,
      curve: zoomCurve,
    );

    animationController.addListener(() {
      final t = positionAnimation.value;
      final z = zoomAnimation.value;

      final lat = lerpDouble(from.latitude, to.latitude, t)!;
      final lng = lerpDouble(from.longitude, to.longitude, t)!;
      final zoom = lerpDouble(fromZoom, toZoom, z)!;

      controller.move(LatLng(lat, lng), zoom);
    });

    await animationController.forward();
    animationController.dispose();
  }
}
