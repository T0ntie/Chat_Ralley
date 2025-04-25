import 'npc_action.dart';
import '../engine/npc.dart';

class RevealAction extends NpcAction{

  RevealAction({required super.trigger, required super.conditions});

  @override
  void excecute(Npc npc) {
    print('${npc.name} reveals');
    npc.reveal();
  }

  static RevealAction actionFromJson(Map<String, dynamic> json) {
    return RevealAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json));
  }
  static void register() {
    NpcAction.registerAction('reveal', RevealAction.actionFromJson);
  }
}