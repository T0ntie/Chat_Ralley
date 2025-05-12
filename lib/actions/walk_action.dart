import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

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
  Future<void> excecute(Npc npc) async {
    print('${npc.name} starts walking to $lat, $lng');
    npc.moveTo(LatLng(lat, lng));
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
