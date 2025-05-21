import '../engine/game_engine.dart';
import '../engine/hotspot.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class ShowHotspotAction extends NpcAction{

  String hotspotName;

  ShowHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotName});

  @override
  Future<bool> excecute(Npc npc) async {
    print('$hotspotName appears');
    Hotspot? spot = GameEngine().getHotspotByName(hotspotName);
    if (spot != null) {
      spot.isVisible = true;
    }
    return true;
  }

  static ShowHotspotAction actionFromJson(Map<String, dynamic> json) {
    final hotspotName = json['hotspot'];
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return ShowHotspotAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer,
        hotspotName: hotspotName);
  }
  static void register() {
    NpcAction.registerAction('showHotspot', ShowHotspotAction.actionFromJson);
  }
}