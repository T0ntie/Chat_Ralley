import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/hotspot.dart';

import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class RevealHotspotAction extends NpcAction{

  String hotspotId;

  RevealHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotId});

  @override
  Future<bool> excecute(Npc npc) async {
    Hotspot? spot = GameEngine().getHotspotById(hotspotId);

    if (spot != null) {
      spot.isVisible = true;
      spot.isRevealed = true;
      print('${spot.name} revealed');
    }
    else {
      print('❌ hotspot ${hotspotId} not found');
      return false;
    }
    return true;
  }

  static RevealHotspotAction actionFromJson(Map<String, dynamic> json) {
    final hotspotId = json['hotspot'];
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return RevealHotspotAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer,
        hotspotId: hotspotId);
  }
  static void register() {
    NpcAction.registerAction('revealHotspot', RevealHotspotAction.actionFromJson);
  }
}