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
    await CameraFlight(
      state: state,
      controller: state.mapController,
      to: hotspot.position,
    ).animate();
  }
}