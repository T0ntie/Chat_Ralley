
import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class FollowAction extends NpcAction{

  FollowAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('NPC ${npc.name} folgt dem Spieler.');
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