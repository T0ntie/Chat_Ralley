import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/engine/hotspot.dart';

import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

class RevealHotspotAction extends NpcAction{

  String hotspotId;

  RevealHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotId});

  @override
  Future<bool> excecute(Npc npc) async {
    Hotspot? spot = GameEngine().getHotspotById(hotspotId);

    if (spot != null) {
      spot.isVisible = true;
      spot.isRevealed = true;
      log.i('🎬 Hotspot "${spot.name}" ist nicht mehr unbekannt.');
      jlog("${spot.name} ist nicht mehr unbekannt.", credits: false);
    }
    else {
      log.w('⚠️ hotspot $hotspotId not found while revealing');
      assert(false, '⚠️ hotspot $hotspotId not found while revealing');
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