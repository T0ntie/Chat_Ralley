import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction{
  String? directiveMessage;
  Set<String>? promptSections;
  BehaveAction({required super.trigger, required super.conditions, super.notification, required this.directiveMessage, required this.promptSections});

  @override
  void excecute(Npc npc) {
    if (promptSections != null && promptSections!.isNotEmpty) {
      npc.injectPromptSections(promptSections!);
    }
    if (directiveMessage case final message?) npc.behave(message);
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['directive'] as String?;
    final promptSectionList = json['injectPromptSections'] as List?;
    final promptSections = promptSectionList != null
        ? Set<String>.from(promptSectionList.whereType<String>())
        : null;
    if (directiveMessage == null && promptSections == null && promptSections!.isNotEmpty) {
      throw ArgumentError("Weder 'directive' noch 'injectPromptSection' versorgt in BehaveAction at + ${json}");
    }
    final (trigger, conditions, notification) = NpcAction.actionFieldsFromJson(json);
    return BehaveAction(
        trigger: trigger,
        conditions: conditions,
        notification: notification,
        directiveMessage: directiveMessage,
        promptSections: promptSections,
    );
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}