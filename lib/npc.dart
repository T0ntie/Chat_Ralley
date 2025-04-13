import 'dart:ui';

import 'package:latlong2/latlong.dart';

enum NPCIcon { unknownIcon, friendlyIcon, dangerIcon }

class NPC {
  final String name;
  final String prompt;
  LatLng position;
  NPCIcon icon;
  Color iconColor;
  String displayName = "unknown";
  double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London

  NPC({
    required this.name,
    required this.prompt,
    required this.position,
    required this.icon,
    required this.iconColor,
  }) : displayName = name;

  void updatePlayerPosition(LatLng playerPosition) {
    print("updating player position");
    this.playerPosition = playerPosition;
    currentDistance = Distance().as(LengthUnit.Meter, position, playerPosition);
  }
}
