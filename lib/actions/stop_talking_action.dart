import 'npc_action.dart';
import '../engine/npc.dart';

class StopTalkingAction extends NpcAction{

  StopTalkingAction({required super.trigger, required super.conditions});

  @override
  void excecute(Npc npc) {
    print('${npc.name} stops talking');
    npc.stopTalking();
  }

  static StopTalkingAction actionFromJson(Map<String, dynamic> json) {
    return StopTalkingAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json));
  }

  static void register() {
    NpcAction.registerAction('stopTalking', StopTalkingAction.actionFromJson);
  }
}