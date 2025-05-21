import '../engine/game_engine.dart';
import '../engine/hotspot.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class RevealHotspotAction extends NpcAction{

  String hotspotName;

  RevealHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotName});

  @override
  Future<bool> excecute(Npc npc) async {
    print('$hotspotName revealed');
    Hotspot? spot = GameEngine().getHotspotByName(hotspotName);
    if (spot != null) {
      spot.isVisible = true;
      spot.isRevealed = true;
    }
    return true;
  }

  static RevealHotspotAction actionFromJson(Map<String, dynamic> json) {
    final hotspotName = json['hotspot'];
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return RevealHotspotAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer,
        hotspotName: hotspotName);
  }
  static void register() {
    NpcAction.registerAction('revealHotspot', RevealHotspotAction.actionFromJson);
  }
}