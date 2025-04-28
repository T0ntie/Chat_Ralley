import 'npc_action.dart';
import '../engine/npc.dart';

class SpawnAction extends NpcAction{

  SpawnAction({required super.trigger, required super.conditions, super.notification});

  @override
  void excecute(Npc npc) {
    print('${npc.name} spawns');
    npc.spawn();
  }

  static SpawnAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return SpawnAction(trigger: trigger, conditions: conditions, notification: notification);
  }
  static void register() {
    NpcAction.registerAction('spawn', SpawnAction.actionFromJson);
  }
}