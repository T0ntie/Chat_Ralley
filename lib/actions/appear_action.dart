import 'npc_action.dart';
import '../engine/npc.dart';

class AppearAction extends NpcAction{

  AppearAction({required super.trigger, required super.conditions, super.notification, super.defer});

  @override
  Future<void> excecute(Npc npc) async {
    print('${npc.name} appears');
    npc.isVisible = true;
    log("${npc.name} ist erschienen.");
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