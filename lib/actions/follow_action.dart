
import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

class FollowAction extends NpcAction{

  FollowAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC ${npc.name} folgt dem Spieler jetzt.');
    npc.startFollowing();
    jlog("${npc.name} folgt dem Spieler.");
    return true;
  }

  static FollowAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return FollowAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer);
  }
  
  static void register() {
    NpcAction.registerAction('follow', FollowAction.actionFromJson);
  }
}