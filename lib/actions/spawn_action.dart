import 'npc_action.dart';
import '../engine/npc.dart';

class SpawnAction extends NpcAction{

  SpawnAction({required super.trigger, required super.conditions});

  @override
  void excecute(Npc npc) {
    print('${npc.name} spawns');
    npc.spawn();
  }

  static SpawnAction actionFromJson(Map<String, dynamic> json) {
    return SpawnAction(trigger: NpcActionTrigger.npcActionTriggerfromJson(json), conditions: NpcAction.conditionsFromJson(json));
  }
  static void register() {
    NpcAction.registerAction('spawn', SpawnAction.actionFromJson);
  }
}