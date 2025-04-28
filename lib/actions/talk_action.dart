import 'npc_action.dart';
import '../engine/npc.dart';

class TalkAction extends NpcAction{
  String triggerMessage;
  TalkAction({required super.trigger, required super.conditions, super.notification, required this.triggerMessage});

  @override
  void excecute(Npc npc) {
    npc.talk(triggerMessage);
  }

  static TalkAction actionFromJson(Map<String, dynamic> json) {
    final triggerMessage = json['trigger'];
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return TalkAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        triggerMessage: triggerMessage);
}

  static void register() {
    NpcAction.registerAction('talk', TalkAction.actionFromJson);
  }
}