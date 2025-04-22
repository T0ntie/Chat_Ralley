import 'package:hello_world/engine/game_element.dart';
import 'package:latlong2/latlong.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class MoveAlongAction extends GameAction{

  final List<LatLng> path;

  MoveAlongAction({required super.trigger, required this.path});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} starts moving along a path');
      element.moveAlong(path);
    } else {
      print('⚠️ MoveAlongAction can only be applied to Npc, but got ${element.runtimeType}');
    }
  }

  static MoveAlongAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    final pathJson = json['params']['path'] as List;
    final path = pathJson.map((p) {
      final lat = p['lat'] as double;
      final lng = p['lng'] as double;
      return LatLng(lat, lng);
    }).toList();
    return MoveAlongAction(trigger: actionTrigger, path: path);
  }

  static void register() {
    GameAction.registerAction('moveAlong', MoveAlongAction.actionFromJson);
  }
}