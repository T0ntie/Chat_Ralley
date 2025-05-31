import 'package:storytrail/gui/intents/show_hotspot_intent.dart';

import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/hotspot.dart';

import 'package:storytrail/gui/intents/ui_intent.dart';
import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class ShowHotspotAction extends NpcAction{

  String hotspotId;

  ShowHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotId});

  @override
  Future<bool> excecute(Npc npc) async {
    Hotspot? spot = GameEngine().getHotspotById(hotspotId);

    if (spot != null) {
      spot.isVisible = true;
      print('${spot.name} appears');
      dispatchUIIntent(ShowHotspotIntent(hotspot: spot));
    }
    else{
      print('❌ hotspot ${hotspotId} not found');
      return false;
    }
    return true;
  }

  static ShowHotspotAction actionFromJson(Map<String, dynamic> json) {
    final hotspotId = json['hotspot'];
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return ShowHotspotAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer,
        hotspotId: hotspotId);
  }
  static void register() {
    NpcAction.registerAction('showHotspot', ShowHotspotAction.actionFromJson);
  }
}