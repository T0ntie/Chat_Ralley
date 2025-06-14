import 'package:aitrailsgo/engine/hotspot.dart';
import 'package:aitrailsgo/gui/camera_flight.dart';
import 'package:aitrailsgo/gui/game_screen.dart';
import 'package:aitrailsgo/services/log_service.dart';
import 'ui_intent.dart';

class ShowHotspotIntent extends UIIntent {
  final Hotspot hotspot;

  ShowHotspotIntent({required this.hotspot});

  @override
  @override
  Future<void> call(GameScreenState state) async {
    log.i('🎨 Starte Kameraflug zu Hotspot "${hotspot.name}"');
    await CameraFlight(
      state: state,
      controller: state.mapController,
      to: hotspot.position,
    ).animate();
  }
}