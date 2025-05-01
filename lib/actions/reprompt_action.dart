import 'npc_action.dart';
import '../engine/npc.dart';

class RepromptAction extends NpcAction {
  String promptFile;

  RepromptAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    required this.promptFile,
  });

  @override
  void excecute(Npc npc) {
    npc.reprompt(promptFile);
  }

  static RepromptAction actionFromJson(Map<String, dynamic> json) {
    final promptFile = json['prompt'];
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(
      json,
    );
    return RepromptAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      promptFile: promptFile,
    );
  }

  static void register() {
    NpcAction.registerAction('reprompt', RepromptAction.actionFromJson);
  }
}
