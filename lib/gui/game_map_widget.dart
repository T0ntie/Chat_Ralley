import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hello_world/app_resources.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/npc.dart';
import 'package:hello_world/gui/npc_info_dialog.dart';
import 'package:latlong2/latlong.dart';

class GameMapWidget extends StatelessWidget {
  final LatLng location;
  final MapController mapController;
  final double currentHeading;
  final double currentMapRotation;
  final bool isMapHeadingBasedOrientation;
  final bool isSimulatingLocation;
  final void Function(LatLng point)? onSimulatedLocationChange;
  final void Function(Npc npc) onNpcChatRequested;

  const GameMapWidget({
    super.key,
    required this.location,
    required this.mapController,
    required this.currentHeading,
    required this.currentMapRotation,
    required this.isMapHeadingBasedOrientation,
    required this.isSimulatingLocation,
    this.onSimulatedLocationChange,
    required this.onNpcChatRequested,
  });


  double _getRotationAngle() {
    return (isMapHeadingBasedOrientation
            ? currentHeading
            : -currentMapRotation) *
        (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final pulse = _getPulseState(GameEngine.conversationDistance);
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: location,
        initialZoom: 16.0,
        onLongPress: (tapPosition, point) {
          if (isSimulatingLocation && onSimulatedLocationChange != null) {
            onSimulatedLocationChange!(point);
          }
        },
        onTap: (tapPosition, point) {
          print('Tapped on location: ${point.latitude}, ${point.longitude}');
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        CircleLayer(
          circles: [
            // 🟢 Hotspot-Radien (nur bei Simulation)
            if (isSimulatingLocation)
              ...GameEngine().hotspots.where((h) => h.isVisible).map(
                    (hotspot) => CircleMarker(
                  point: hotspot.position,
                  radius: hotspot.radius,
                  useRadiusInMeter: true,
                  color: ResourceColors.hotspotCircle.withAlpha((0.1 * 255).toInt()),
                  borderColor: ResourceColors.hotspotCircle.withAlpha((0.5 * 255).toInt()),
                  borderStrokeWidth: 2,
                ),
              ),
            // 🔵 Puls-Kreis (immer sichtbar)
            CircleMarker(
              point: location,
              radius: pulse.radius,
              useRadiusInMeter: true,
              color:
                  pulse.maxReached
                      ? Colors.transparent
                      : ResourceColors.playerPositionCircle.withAlpha(
                        (pulse.colorFade * 0.5 * 255).toInt(),
                      ),
              borderColor:
                  pulse.maxReached
                      ? ResourceColors.playerPositionFadeoutCircle.withAlpha(
                        ((pulse.colorFade + 0.2) * 255).toInt(),
                      )
                      : ResourceColors.playerPositionCircle.withAlpha(
                        (pulse.colorFade * 0.5 * 255).toInt(),
                      ),
              borderStrokeWidth: 2,
            ),
            if (pulse.maxReached)
              CircleMarker(
                point: location,
                radius: GameEngine.conversationDistance,
                useRadiusInMeter: true,
                color: ResourceColors.playerPositionCircle.withAlpha(
                  (pulse.colorFade * 0.5 * 255).toInt(),
                ),
                borderColor: ResourceColors.playerPositionCircle.withAlpha(
                  (pulse.colorFade * 0.3 * 255).toInt(),
                ),
                borderStrokeWidth: 2,
              ),
          ],
        ),

        MarkerLayer(
          markers: [
            Marker(
              point: location,
              child: Transform.rotate(
                angle: currentHeading *(pi / 180), //_getRotationAngle(),
                child: AppIcons.playerPosition,
              ),
            ),
            ..._buildHotspotMarkers(context),
            ..._buildNpcMarkers(context),
          ],
        ),
      ],
    );
  }

  List<Marker> _buildHotspotMarkers(BuildContext context) {
    final hotspots = GameEngine().hotspots;

    return hotspots.where((h) => h.isVisible).map((hotspot) {
      return Marker(
        point: hotspot.position,
        width: 60,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                print("🎯 Tapped on Hotspot ${hotspot.name}");
              },
              child: Transform.rotate(
                angle: _getRotationAngle(),
                child: AppIcons.hotspot(context),
              ),
            ),
            const SizedBox(height: 4),
            if (hotspot.isRevealed)
              Text(
                hotspot.name,
                style: TextStyle(
                  fontSize: 11,
                  color: ResourceColors.npcName,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  List<Marker> _buildNpcMarkers(BuildContext context) {
    final npcs = GameEngine().npcs;

    return npcs.where((npc) => npc.isVisible).map((npc) {
      return Marker(
        point: npc.currentPosition,
        width: 170.0,
        height: 100.0,
        child: Transform.rotate(
          angle: _getRotationAngle(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => NpcInfoDialog(npc: npc, onNpcChatRequested: onNpcChatRequested),
                  );
                },
                child: AppIcons.npc(context, npc.icon),
              ),
              if (npc.hasSomethingToSay)
                Positioned(
                  top: 5,
                  right: 40,
                  child: GestureDetector(
                    onTap: () {
                      onNpcChatRequested.call(npc);
                      /*
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatPage(npc: npc)),
                      );
                      */
                    },
                    child: AppIcons.chatBubble(context),
                  ),
                ),
              Positioned(
                bottom: 15,
                child: Text(
                  npc.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: ResourceColors.npcName,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class PulseState {
  final double radius;
  final bool maxReached;
  final double colorFade;

  PulseState({
    required this.radius,
    required this.maxReached,
    required this.colorFade,
  });
}

PulseState _getPulseState(double baseRadius) {
  const pulseDuration = 2000; // Millisekunden
  const double maxFactor = 1.6;
  const double whiteRingStart = 1.0;

  final int now = DateTime.now().millisecondsSinceEpoch;
  final double t = (now % pulseDuration) / pulseDuration;
  final double currentFactor = t * maxFactor;
  final double radius = baseRadius * currentFactor;
  final double colorFade = (1 - t).abs();
  final bool maxReached = currentFactor >= whiteRingStart;

  return PulseState(
    radius: radius,
    maxReached: maxReached,
    colorFade: colorFade,
  );
}
