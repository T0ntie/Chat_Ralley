import 'npc_action.dart';
import '../engine/npc.dart';

class RevealAction extends NpcAction{

  RevealAction({required super.trigger, required super.conditions, super.notification});

  @override
  void excecute(Npc npc) {
    print('${npc.name} reveals');
    npc.reveal();
  }

  static RevealAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return RevealAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification);
  }
  static void register() {
    NpcAction.registerAction('reveal', RevealAction.actionFromJson);
  }
}