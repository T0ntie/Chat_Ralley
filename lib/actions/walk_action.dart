import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class WalkAction extends NpcAction {
  final double lat;
  final double lng;

  WalkAction({
    required super.trigger,
    required super.conditions,
    required this.lat,
    required this.lng,
  });

  @override
  void excecute(Npc npc) {
    print('${npc.name} starts walking to ${lat}, ${lng}');
    npc.moveTo(LatLng(lat, lng));
  }

  static WalkAction actionFromJson(Map<String, dynamic> json) {
    final lat = json['params']['lat'];
    final lng = json['params']['lng'];
    return WalkAction(
      trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
      conditions: NpcAction.conditionsFromJson(json),
      lat: lat,
      lng: lng,
    );
  }

  static void register() {
    NpcAction.registerAction('walkTo', WalkAction.actionFromJson);
  }
}
