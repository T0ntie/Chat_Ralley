import 'package:storytrail/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class WalkAction extends NpcAction {
  final double lat;
  final double lng;

  WalkAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.lat,
    required this.lng,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC "${npc.name}" bewegt sich Richtung $lat, $lng');
    npc.moveTo(LatLng(lat, lng));
    return true;
  }

  static WalkAction actionFromJson(Map<String, dynamic> json) {
    LatLng toPosition = StoryLine.positionFromJson(json);
    final (trigger, conditions, notification,defer) = NpcAction.actionFieldsFromJson(
      json,
    );
    return WalkAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      lat: toPosition.latitude,
      lng: toPosition.longitude,
    );
  }

  static void register() {
    NpcAction.registerAction('walkTo', WalkAction.actionFromJson);
  }
}
