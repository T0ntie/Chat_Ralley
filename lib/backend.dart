import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'npc.dart';

class Backend {
  static List<NPC> loadNPCs() {
    return [
      NPC(
        name: "Alice im Wunderland",
        prompt: "Hallo ich bin Alice",
        position: LatLng(48.08418, 16.29050),
        icon: NPCIcon.unknownIcon,
        iconColor: Colors.grey,
      ),
      NPC(
        name: "Bozzi im Wohnzimmer",
        prompt: "Hallo ich bin Bozzi",
        position: LatLng(48.090382361745675, 16.296814606890685),
        icon: NPCIcon.unknownIcon,
        iconColor: Colors.grey,
      ),
      NPC(
        name: "Pezi",
        prompt: "Mechtlers Wille geschehe",
        position: LatLng(48.248951, 16.369782),
        icon: NPCIcon.unknownIcon,
        iconColor: Colors.grey,
      ),
    ];
  }
}
