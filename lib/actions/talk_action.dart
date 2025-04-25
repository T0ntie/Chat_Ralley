import 'npc_action.dart';
import '../engine/npc.dart';

class TalkAction extends NpcAction{
  String triggerMessage;
  TalkAction({required super.trigger, required super.conditions, required this.triggerMessage});

  @override
  void excecute(Npc npc) {
    npc.talk(triggerMessage);
  }

  static TalkAction actionFromJson(Map<String, dynamic> json) {
    final triggerMessage = json['params']['trigger'];
    return TalkAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json),
        triggerMessage: triggerMessage,
    );
}

  static void register() {
    NpcAction.registerAction('talk', TalkAction.actionFromJson);
  }
}