
import 'npc_action.dart';
import '../engine/npc.dart';

class FollowAction extends NpcAction{

  FollowAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    print('${npc.name} starts following you');
    npc.startFollowing();
    log("${npc.name} folgt dem Spieler");
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