import 'package:hello_world/engine/game_element.dart';
import 'package:latlong2/latlong.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class WalkAction extends GameAction{

  final double lat;
  final double lng;

  WalkAction({required super.trigger, required this.lat, required this.lng});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} starts walking to ${lat}, ${lng}');
      element.moveTo(LatLng(lat, lng));
    } else {
      print('⚠️ WalkAction can only be applied to Npc, but got ${element.runtimeType}');
    }
  }

  static WalkAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    final lat = json['params']['lat'];
    final lng = json['params']['lng'];

    return WalkAction(trigger: actionTrigger, lat: lat, lng: lng);
  }

  static void register() {
    GameAction.registerAction('walkTo', WalkAction.actionFromJson);
  }

}