import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class WalkAction extends NpcAction{

  final double lat;
  final double lng;

  WalkAction({required super.trigger, required this.lat, required this.lng});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} starts walking to ${lat}, ${lng}');
    npc.moveTo(LatLng(lat, lng));
  }

  static WalkAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    final lat = json['params']['lat'];
    final lng = json['params']['lng'];

    return WalkAction(trigger: actionTrigger, lat: lat, lng: lng);
  }

  static void register() {
    NpcAction.registerAction('walkTo', WalkAction.actionFromJson);
  }

}