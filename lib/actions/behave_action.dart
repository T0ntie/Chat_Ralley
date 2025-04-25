import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction{
  String directiveMessage;
  BehaveAction({required super.trigger, required super.conditions, required this.directiveMessage});

  @override
  void excecute(Npc npc) {
    npc.behave(directiveMessage);
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['params']['directive'];
    return BehaveAction(
        trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
        conditions: NpcAction.conditionsFromJson(json),
        directiveMessage: directiveMessage);
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}