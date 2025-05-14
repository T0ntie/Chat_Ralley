import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class LeadAction extends NpcAction {
  final double lat;
  final double lng;
  final double waitDistance = 100.0;
  final double continueDistance = 20;

  LeadAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.lat,
    required this.lng,
  });

  @override
  Future<void> excecute(Npc npc) async {
    print('${npc.name} starts leading to $lat, $lng');
    npc.leadTo(LatLng(lat, lng));
    log("${npc.name} führt den Spieler an einem bestimmten Ort.");
  }

  static LeadAction actionFromJson(Map<String, dynamic> json) {
    LatLng toPosition = StoryLine.positionFromJson(json);
    final (trigger, conditions, notification,defer) = NpcAction.actionFieldsFromJson(
      json,
    );
    return LeadAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      lat: toPosition.latitude,
      lng: toPosition.longitude,
    );
  }

  static void register() {
    NpcAction.registerAction('leadTo', LeadAction.actionFromJson);
  }
}
