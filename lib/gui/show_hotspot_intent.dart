import 'package:flutter/animation.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/engine/hotspot.dart';
import 'package:storytrail/gui/camera_flight.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'ui_intent.dart';

class ShowHotspotIntent extends UIIntent {
  final Hotspot hotspot;

  ShowHotspotIntent({required this.hotspot});

  @override
  @override
  Future<void> call(GameScreenState state) async {
    final controller = state.mapController;

    await CameraFlight(
      state: state,
      controller: state.mapController,
      to: hotspot.position,
    ).animate();
  }
}
/*
    final animator = CameraFlightAnimator(
      vsync: state,
      controller: controller,
    );

    final from = controller.camera.center;
    final fromZoom = controller.camera.zoom;

    final to = hotspot.position;
    final toZoom = 17.0;
    final midZoom = 16.0;

    final distanceCalc = const Distance();
    final dist = distanceCalc(from, to);

    if (dist < 100) {
      controller.move(to, toZoom);
      print("📍 Jumped to nearby Hotspot: ${hotspot.name}");
      return;
    }

    Duration dynamicDuration(double base) {
      final millis = (base + dist / 8).clamp(1200, 5000);
      return Duration(milliseconds: millis.toInt());
    }

    final midpoint = curvedMidpoint(from, to);

    final base = 1000.0;

    // ✈️ Hinflug – Position + separater sanfter Zoom
    await animator.animateCameraSplitZoom(
      from: from,
      to: to,
      fromZoom: fromZoom,
      toZoom: midZoom,
      duration: dynamicDuration(base),
      positionCurve: Curves.easeInOut,
      zoomCurve: Curves.easeOutQuad,
    );
*/

/*
    await animator.animateCameraSplitZoom(
      from: midpoint,
      to: to,
      fromZoom: midZoom,
      toZoom: toZoom,
      duration: dynamicDuration(base),
      positionCurve: Curves.easeInOut,
      zoomCurve: Curves.easeInQuad,
    );
*/
/*

    print("📍 Moved to Hotspot: ${hotspot.name}");

    await Future.delayed(const Duration(seconds: 1));

    // 🔙 Rückflug – einfache Kamerabewegung (klassisch)
    await animator.animateCamera(
      from: to,
      to: from,
      fromZoom: toZoom,
      toZoom: midZoom,
      duration: dynamicDuration(base),
    );
*/

/*
    await animator.animateCamera(
      from: midpoint,
      to: from,
      fromZoom: midZoom,
      toZoom: fromZoom,
      duration: dynamicDuration(base),
    );
*/
/*
    print("🔙 Returned to original position");
  }


  LatLng curvedMidpoint(LatLng a, LatLng b) {
    final lat = (a.latitude + b.latitude) / 2;
    final lng = (a.longitude + b.longitude) / 2;

    // Kleine Verschiebung nach "oben" (in Kartenrichtung)
    const offset = 0.0015;
    return LatLng(lat + offset, lng); // Versatz nur in Latitude
  }
*/
//}

