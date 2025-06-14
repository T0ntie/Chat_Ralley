import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

class StopTalkingAction extends NpcAction{

  StopTalkingAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC "${npc.name}" beendet das Gespräch.');
    jlog('"${npc.name}" beendet abrupt das Gespräch.');
    await npc.stopTalking();
    return true;
  }

  static StopTalkingAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return StopTalkingAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer);
  }

  static void register() {
    NpcAction.registerAction('stopTalking', StopTalkingAction.actionFromJson);
  }
}