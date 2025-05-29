import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class StopTalkingAction extends NpcAction{

  StopTalkingAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    print('${npc.name} stops talking');
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