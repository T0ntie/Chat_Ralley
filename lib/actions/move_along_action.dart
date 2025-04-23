import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class MoveAlongAction extends NpcAction{

  final List<LatLng> path;

  MoveAlongAction({required super.trigger, required this.path});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} starts moving along a path');
    npc.moveAlong(path);
  }

  static MoveAlongAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    final pathJson = json['params']['path'] as List;
    final path = pathJson.map((p) {
      final lat = p['lat'] as double;
      final lng = p['lng'] as double;
      return LatLng(lat, lng);
    }).toList();
    return MoveAlongAction(trigger: actionTrigger, path: path);
  }

  static void register() {
    NpcAction.registerAction('moveAlong', MoveAlongAction.actionFromJson);
  }
}