import 'package:aitrailsgo/gui/intents/show_hotspot_intent.dart';
import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/engine/hotspot.dart';
import 'package:aitrailsgo/gui/intents/ui_intent.dart';
import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

class ShowHotspotAction extends NpcAction{

  String hotspotId;

  ShowHotspotAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.hotspotId});

  @override
  Future<bool> excecute(Npc npc) async {
    Hotspot? spot = GameEngine().getHotspotById(hotspotId);

    if (spot != null) {
      spot.isVisible = true;
      log.i('🎬 Hotspot "${spot.name}" erscheint auf der Karte.');
      jlog("${spot.name} erscheint auf der Karte.", credits: false);
      dispatchUIIntent(ShowHotspotIntent(hotspot: spot));
    }
    else{
      log.e('❌ hotspot $hotspotId not found in showHotspotAction', stackTrace: StackTrace.current);
      assert(false, '❌ hotspot $hotspotId not found showHotspotAction');
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