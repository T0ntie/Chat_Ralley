import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction{
  String directiveMessage;
  BehaveAction({required super.trigger, required this.directiveMessage});

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    npc.behave(directiveMessage);
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    NpcActionTrigger actionTrigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    final directiveMessage = json['params']['directive'];
    return BehaveAction(trigger: actionTrigger, directiveMessage: directiveMessage);
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}