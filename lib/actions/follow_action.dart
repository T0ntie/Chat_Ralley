
import 'npc_action.dart';
import '../engine/npc.dart';

class FollowAction extends NpcAction{

  FollowAction({required super.trigger});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} starts following you');
    npc.startFollowing();
  }

  static FollowAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    return FollowAction(trigger: actionTrigger);
  }
  
  static void register() {
    NpcAction.registerAction('follow', FollowAction.actionFromJson);
  }
}