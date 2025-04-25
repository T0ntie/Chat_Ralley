
import 'npc_action.dart';
import '../engine/npc.dart';

class FollowAction extends NpcAction{

  FollowAction({required super.trigger, required super.conditions});

  @override
  void excecute(Npc npc) {
    print('${npc.name} starts following you');
    npc.startFollowing();
  }

  static FollowAction actionFromJson(Map<String, dynamic> json) {
    return FollowAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json));

  }
  
  static void register() {
    NpcAction.registerAction('follow', FollowAction.actionFromJson);
  }
}