import 'npc_action.dart';
import '../engine/npc.dart';

class StopMovingAction extends NpcAction{

  StopMovingAction({required super.trigger, required super.conditions});

  @override
  void excecute(Npc npc) {
    print('${npc.name} stops');
    npc.stopMoving();
  }

  static StopMovingAction actionFromJson(Map<String, dynamic> json) {
    return StopMovingAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json));
  }

  static void register() {
    NpcAction.registerAction('stopMoving', StopMovingAction.actionFromJson);
  }
}