import 'npc_action.dart';
import '../engine/npc.dart';

class AppearAction extends NpcAction{

  AppearAction({required super.trigger});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} appears');
    npc.isVisible = true;
  }

  static AppearAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    return AppearAction(trigger: actionTrigger);
  }

  static void register() {
    NpcAction.registerAction('appear', AppearAction.actionFromJson);
  }

}