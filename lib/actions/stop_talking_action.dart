import 'npc_action.dart';
import '../engine/npc.dart';

class StopTalkingAction extends NpcAction{

  StopTalkingAction({required super.trigger, required super.conditions, super.notification});

  @override
  void excecute(Npc npc) {
    print('${npc.name} stops talking');
    npc.stopTalking();
  }

  static StopTalkingAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return StopTalkingAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification);
  }

  static void register() {
    NpcAction.registerAction('stopTalking', StopTalkingAction.actionFromJson);
  }
}