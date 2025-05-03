import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction{
  String? directiveMessage;
  String? promptSection;
  BehaveAction({required super.trigger, required super.conditions, super.notification, required this.directiveMessage, required this.promptSection});

  @override
  void excecute(Npc npc) {
    if (promptSection case final section?) npc.injectPromptSection(section);
    if (directiveMessage case final message?) npc.behave(message);
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['directive'] as String?;
    final promptSection = json['injectPromptSection'] as String?;
    if (directiveMessage == null && promptSection == null) {
      throw ArgumentError("Weder 'directive' noch 'injectPromptSection' versorgt in BehaveAction at + ${json}");
    }
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return BehaveAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        directiveMessage: directiveMessage,
        promptSection: promptSection,
    );
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}