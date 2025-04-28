import 'npc_action.dart';
import '../engine/npc.dart';

class AppearAction extends NpcAction{

  AppearAction({required super.trigger, required super.conditions, super.notification});

  @override
  void excecute(Npc npc) {
    print('${npc.name} appears');
    npc.isVisible = true;
  }

  static AppearAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return AppearAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification);
  }

  static void register() {
    NpcAction.registerAction('appear', AppearAction.actionFromJson);
  }

}