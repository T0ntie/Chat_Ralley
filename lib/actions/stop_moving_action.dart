import 'npc_action.dart';
import '../engine/npc.dart';

class StopMovingAction extends NpcAction{

  StopMovingAction({required super.trigger});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} stops');
    npc.stopMoving();
  }

  static StopMovingAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    return StopMovingAction(trigger: actionTrigger);
  }

  static void register() {
    NpcAction.registerAction('stopMoving', StopMovingAction.actionFromJson);
  }
}