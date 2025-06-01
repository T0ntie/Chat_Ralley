import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class TalkAction extends NpcAction{
  String triggerMessage;
  TalkAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.triggerMessage});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('NPC "${npc.name}" meldet sich zu Wort: "$triggerMessage"');
    await npc.talk(triggerMessage);
    return true;
  }

  static TalkAction actionFromJson(Map<String, dynamic> json) {
    final triggerMessage = json['trigger'];
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return TalkAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer,
        triggerMessage: triggerMessage);
}

  static void register() {
    NpcAction.registerAction('talk', TalkAction.actionFromJson);
  }
}