import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class NotifyAction extends NpcAction{

  NotifyAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC ${npc.name} wird benachrichtigt: "$notification".');
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