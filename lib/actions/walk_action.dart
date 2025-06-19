import 'package:aitrailsgo/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

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
    log.i('🎬 NPC "${npc.name}" bewegt sich zur Position $lat, $lng');
    jlog('${npc.name} bewegt sich zur Position $lat, $lng', credits: false);
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
