import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:storytrail/app_resources.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/moving_controller.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/gui/npc_info_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/services/log_service.dart';

class GameMapWidget extends StatelessWidget {
  final LatLng location;
  final MapController mapController;
  final double currentHeading;
  final double currentMapRotation;
  final bool isMapHeadingBasedOrientation;
  final bool isSimulatingLocation; //fixme das darf wohl nicht stateless sein
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

    LatLng targetPosition = GameEngine().playerMovementController.targetPosition;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: location,
        initialZoom: 18.0,

        onTap: (tapPosition, point) {
          log.d('Tapped on location: ${point.latitude}, ${point.longitude}');
          if (isSimulatingLocation) { //fixme hier hats was, simuliert und hat dennoch GPS
            GameEngine().playerMovementController.moveTo(point);
          }
        },

        onLongPress: (tapPosition, point) {
          if (isSimulatingLocation) {
            GameEngine().playerMovementController.teleportTo(point);
          }
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
              ...GameEngine().hotspots
                  .where((h) => h.isVisible)
                  .map(
                    (hotspot) => CircleMarker(
                      point: hotspot.position,
                      radius: hotspot.radius,
                      useRadiusInMeter: true,
                      color: ResourceColors.hotspotCircle.withAlpha(
                        (0.1 * 255).toInt(),
                      ),
                      borderColor: ResourceColors.hotspotCircle.withAlpha(
                        (0.5 * 255).toInt(),
                      ),
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
            if (targetPosition != null)
              Marker(
                point: (targetPosition),
                width: 40,
                height: 40,
                child: Transform.rotate(
                  angle: currentHeading * (pi / 180),
                  child: Icon(Icons.navigation, color: Colors.grey, size: 24),
                ),
              ),
            Marker(
              point: location,
              width: 40,
              height: 40,
              child: Transform.rotate(
                angle: currentHeading * (pi / 180),
                child:
                GameEngine().isGPSSimulating
                    ? Icon(
                  Icons.my_location,
                  color: Color(0xFF6A0DAD),
                  size: 40,
                )
                    : AppIcons.playerPosition,
              ),
            ),

            ..._buildHotspotMarkers(context),
            ..._buildNpcMarkers(context),
            if (GameEngine().lastSaveLocation != null)
              _buildLastSavePositionMarker(context),
          ],
        ),
      ],
    );
  }

  Marker _buildLastSavePositionMarker(BuildContext context) {
    String? saveDate;
    if (GameEngine().lastSaveTime != null){
      final lastSave = GameEngine().lastSaveTime!;
      final day = lastSave.day.toString().padLeft(2, '0');
      final month = lastSave.month.toString().padLeft(2, '0');
      final hour = lastSave.hour.toString().padLeft(2, '0');
      final minute = lastSave.minute.toString().padLeft(2, '0');
      saveDate = '$day.$month.${lastSave.year} – $hour:$minute';
    }
    return
      Marker(
        point: GameEngine().lastSaveLocation!,
        width: 150,
        height: 60,
        child: Transform.rotate(
          angle: _getRotationAngle(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/icons/save-pin.svg",
                width: 30,
                height: 30,
              ),
              const SizedBox(height: 4),
              if (saveDate != null)
              Text(
                saveDate,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: ResourceColors.npcName,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
  }

  List<Marker> _buildHotspotMarkers(BuildContext context) {
    final hotspots = GameEngine().hotspots;

    return hotspots.where((h) => h.isVisible).map((hotspot) {
      return Marker(
        point: hotspot.position,
        width: 60,
        height: 80,
        child: Transform.rotate(
          angle: _getRotationAngle(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => InfoDialog(
                          title: hotspot.name,
                          imageUriPath: GameEngine().hotspotImagePath(hotspot),
                          distanceText:
                              "Entfernung: ${hotspot.currentDistance} Meter",
                          noteText: null,
                          onPrimaryAction: null,
                        ),
                  );
                },
                child: SvgPicture.asset(
                  'assets/icons/flag.svg',
                  width: 48,
                  height: 48,
                ), //AppIcons.hotspot(context),
              ),
              const SizedBox(height: 4),
              if (hotspot.isRevealed)
                SizedBox(
                  width: 60,
                  child: Text(
                    hotspot.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                    builder:
                        (ctx) => InfoDialog(
                          title: npc.displayName,
                          //imageAssetPath: "assets/story/${npc.displayImageAsset}",
                          imageUriPath: GameEngine().npcImagePath(npc),
                          distanceText:
                              "Entfernung: ${npc.currentDistance} Meter",
                          noteText:
                              !(npc.isInCommunicationDistance)
                                  ? "Komm näher, um mit ${npc.displayName} zu kommunizieren."
                                  : null,
                          onPrimaryAction:
                              npc.isInCommunicationDistance
                                  ? () => onNpcChatRequested(npc)
                                  : null,
                        ),
                  );
                },
                //child: AppIcons.npc(context, npc.icon), //Image.asset('assets/story/icons/trex2.png'),
                child:
                    npc.iconAsset == null
                        ? AppIcons.npc(context, npc.icon)
                        : Image.asset('assets/story/${npc.iconAsset}'),
              ),
              if (npc.hasSomethingToSay)
                Positioned(
                  top: 5,
                  right: 40,
                  child: GestureDetector(
                    onTap:
                        npc.isInCommunicationDistance
                            ? () => onNpcChatRequested(npc)
                            : null,
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
