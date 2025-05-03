import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction{
  String? directiveMessage;
  String? promptTag;
  BehaveAction({required super.trigger, required super.conditions, super.notification, required this.directiveMessage, required this.promptTag});

  @override
  void excecute(Npc npc) {
    if (promptTag case final tag?) npc.injectTaggedPrompts(tag);
    if (directiveMessage case final message?) npc.behave(message);
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['directive'] as String?;
    final promptTag = json['promptTag'] as String?;
    if (directiveMessage == null && promptTag == null) {
      throw ArgumentError("Weder 'directive' noch 'promptTag' versorgt in BehaveAction at + ${json}");
    }
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return BehaveAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        directiveMessage: directiveMessage,
        promptTag: promptTag,
    );
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}