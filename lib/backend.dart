import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'npc.dart';

class Backend {
  static List<NPC> loadNPCs() {
    return [
      NPC(
        name: "Alice im Wunderland",
        prompt: "Du bist Alice im Wunderland, und schickst manchmal Grüße von der Herzkönigin",
        position: LatLng(48.08418, 16.29050),
        icon: NPCIcon.unknownIcon,
        iconColor: Colors.grey,
      ),
      NPC(
        name: "Bozzi im Wohnzimmer",
        prompt: "Du bis ein kleiner NPC Hund namens Bozzi. Ende deine Antworten immer mit einem freundlichen Wuff!",
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
