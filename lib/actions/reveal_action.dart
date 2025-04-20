import 'npc_action.dart';
import '../engine/npc.dart';

class RevealAction extends NpcAction{

  RevealAction({required super.trigger});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} reveals');
    npc.reveal();
  }

  static RevealAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    return RevealAction(trigger: actionTrigger);
  }
  static void register() {
    NpcAction.registerAction('reveal', RevealAction.actionFromJson);
  }
}