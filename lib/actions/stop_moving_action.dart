import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class StopMovingAction extends NpcAction{

  StopMovingAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    print('${npc.name} stops');
    npc.stopMoving();
    return true;
  }

  static StopMovingAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return StopMovingAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer);
  }

  static void register() {
    NpcAction.registerAction('stopMoving', StopMovingAction.actionFromJson);
  }
}