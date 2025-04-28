import 'npc_action.dart';
import '../engine/npc.dart';

class StopMovingAction extends NpcAction{

  StopMovingAction({required super.trigger, required super.conditions, super.notification});

  @override
  void excecute(Npc npc) {
    print('${npc.name} stops');
    npc.stopMoving();
  }

  static StopMovingAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return StopMovingAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification);
  }

  static void register() {
    NpcAction.registerAction('stopMoving', StopMovingAction.actionFromJson);
  }
}