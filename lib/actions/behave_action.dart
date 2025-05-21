import '../engine/game_engine.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class BehaveAction extends NpcAction {
  String? directiveMessage;
  String? promptTag;

  BehaveAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.directiveMessage,
    String? promptTag,
  }): promptTag = promptTag?.norm;

  @override
  Future<bool> excecute(Npc npc) async {
    if (promptTag case final tag?) npc.injectTaggedPrompts(tag);
    if (directiveMessage case final message?) npc.behave(message);
    return true;
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['directive'] as String?;
    final promptTag = json['promptTag'] as String?;
    if (directiveMessage == null && promptTag == null) {
      throw ArgumentError(
        "Weder 'directive' noch 'promptTag' versorgt in BehaveAction at + $json",
      );
    }
    final (
      trigger,
      conditions,
      notification,
      defer,
    ) = NpcAction.actionFieldsFromJson(json);
    return BehaveAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      directiveMessage: directiveMessage,
      promptTag: promptTag,
    );
  }

  static void register() {
    NpcAction.registerAction('behave', BehaveAction.actionFromJson);
  }
}
