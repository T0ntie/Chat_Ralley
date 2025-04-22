import 'npc_action.dart';
import '../engine/npc.dart';

class SpawnAction extends NpcAction{

  SpawnAction({required super.trigger});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} spawns');
    npc.spawn();
  }

  static SpawnAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    return SpawnAction(trigger: actionTrigger);
  }
  static void register() {
    NpcAction.registerAction('spawn', SpawnAction.actionFromJson);
  }
}