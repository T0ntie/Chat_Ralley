import 'npc_action.dart';
import '../engine/npc.dart';

class NotifyAction extends NpcAction{

  NotifyAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    return true;
  }

  static NotifyAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return NotifyAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer);
  }

  static void register() {
    NpcAction.registerAction('notify', NotifyAction.actionFromJson);
  }

}