import 'dart:ui'; // für lerpDouble
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/engine/hotspot.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'ui_intent.dart';

import 'dart:ui'; // für lerpDouble
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/engine/hotspot.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'ui_intent.dart';

class ShowHotspotIntent extends UIIntent {
  final Hotspot hotspot;

  ShowHotspotIntent({required this.hotspot});

  @override
  Future<void> call(GameScreenState state) async {
    final controller = state.mapController;

    final from = controller.camera.center;
    final fromZoom = controller.camera.zoom;

    final to = hotspot.position;
    final toZoom = 17.0;
    final midZoom = 16.0; // Flughöhe

    final distanceCalc = const Distance();
    final dist = distanceCalc(from, to);

    // ✂️ Optional: Überspringe Animation bei kurzen Distanzen
    if (dist < 100) {
      controller.move(to, toZoom);
      print("📍 Jumped to nearby Hotspot: ${hotspot.name}");
      return;
    }

    Duration dynamicDuration(double base) {
      final millis = (base + dist / 8).clamp(1200, 5000);
      return Duration(milliseconds: millis.toInt());
    }


    // 🔁 Gemeinsamer Animations-Helfer
    Future<void> animateTo(
        LatLng start,
        LatLng end,
        double startZoom,
        double endZoom,
        Duration duration,
        ) async {
      final animationController = AnimationController(
        duration: duration,
        vsync: state,
      );

      animationController.addListener(() {
        final t = animationController.value;
        final lat = lerpDouble(start.latitude, end.latitude, t)!;
        final lng = lerpDouble(start.longitude, end.longitude, t)!;
        final zoom = lerpDouble(startZoom, endZoom, t)!;
        controller.move(LatLng(lat, lng), zoom);
      });

      await animationController.forward();
      animationController.dispose();
    }

    // 🛫 Phase 1: Zur Mitte mit mittlerem Zoom
    final midpoint = LatLng(
      (from.latitude + to.latitude) / 2,
      (from.longitude + to.longitude) / 2,
    );

    double base = 1000;
    await animateTo(from, midpoint, fromZoom, midZoom, dynamicDuration(base));

    // 🛬 Phase 2: Von Mitte zum Ziel (reinzoomen)
    await animateTo(midpoint, to, midZoom, toZoom, dynamicDuration(base));

    print("📍 Moved to Hotspot: ${hotspot.name}");

    // ⏱️ Verweile einen Moment
    await Future.delayed(const Duration(seconds: 1));

    // 🔁 Phase 3: Zurück zur Mitte
    await animateTo(to, midpoint, toZoom, midZoom, dynamicDuration(base));

    // 🔽 Phase 4: Zurück zum Startpunkt
    await animateTo(midpoint, from, midZoom, fromZoom, dynamicDuration(base));

    print("🔙 Returned to original position");
  }
}

