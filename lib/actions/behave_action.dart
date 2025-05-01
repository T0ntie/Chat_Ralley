import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction{
  String directiveMessage;
  BehaveAction({required super.trigger, required super.conditions, super.notification, required this.directiveMessage});

  @override
  void excecute(Npc npc) {
    npc.behave(directiveMessage);


  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['directive'];
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return BehaveAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        directiveMessage: directiveMessage);
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}