import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/hotspot.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class RevealHotspotAction extends NpcAction{

  String hotspotName;

  RevealHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotName});

  @override
  void excecute(Npc npc) {
    print('$hotspotName revealed');
    Hotspot? spot = GameEngine().getHotspotByName(hotspotName);
    if (spot != null) {
      spot.isVisible = true;
      spot.isRevealed = true;
    }
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