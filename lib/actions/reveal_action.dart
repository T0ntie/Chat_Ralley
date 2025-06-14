import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

class RevealAction extends NpcAction{

  RevealAction({required super.trigger, required super.conditions, super.defer, super.notification});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC "${npc.name}" ist nicht mehr anonym.');
    npc.reveal();
    jlog("${npc.name} stellt sich vor.");
    return true;
  }

  static RevealAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return RevealAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer);
  }
  static void register() {
    NpcAction.registerAction('reveal', RevealAction.actionFromJson);
  }
}