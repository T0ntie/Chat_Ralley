import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

class AppearAction extends NpcAction{

  AppearAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 ${npc.name} wird sichtbar.');
    npc.isVisible = true;
    jlog("${npc.name} ist erschienen.");
    return npc.isVisible;
  }

  static AppearAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    return AppearAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        defer: defer);
  }

  static void register() {
    NpcAction.registerAction('appear', AppearAction.actionFromJson);
  }
}