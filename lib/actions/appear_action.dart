import 'npc_action.dart';
import '../engine/npc.dart';

class AppearAction extends NpcAction{

  AppearAction({required super.trigger, required super.conditions});

  @override
  void excecute(Npc npc) {
    print('${npc.name} appears');
    npc.isVisible = true;
  }

  static AppearAction actionFromJson(Map<String, dynamic> json) {
    return AppearAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json));
  }

  static void register() {
    NpcAction.registerAction('appear', AppearAction.actionFromJson);
  }

}