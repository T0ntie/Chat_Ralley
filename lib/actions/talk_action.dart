import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class TalkAction extends NpcAction{
  String triggerMessage;
  TalkAction({required super.trigger, required this.triggerMessage});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    npc.talk(triggerMessage);
  }

  static TalkAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    final triggerMessage = json['params']['trigger'];
    return TalkAction(trigger: actionTrigger, triggerMessage: triggerMessage);
  }

  static void register() {
    NpcAction.registerAction('talk', TalkAction.actionFromJson);
  }
}