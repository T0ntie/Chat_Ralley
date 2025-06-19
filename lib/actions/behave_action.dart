import 'package:aitrailsgo/engine/game_engine.dart';

import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

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
  }) : promptTag = promptTag?.norm;

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 ${npc.name} bekommt neue Instruktionen: tag:"$promptTag", behave: "$directiveMessage".');
    jlog("${npc.name} bekommt neue Instruktionen: tag: $promptTag, behave: $directiveMessage", credits: false);
    if (promptTag case final tag?) npc.injectTaggedPrompts(tag);
    if (directiveMessage case final message?) npc.behave(message);
    return true;
  }

  static BehaveAction actionFromJson(Map<String, dynamic> json) {
    final directiveMessage = json['directive'] as String?;
    final promptTag = json['promptTag'] as String?;
    if (directiveMessage == null && promptTag == null) {
      log.e(
        '❌ Invalid Json neither "directive" nor "promptTag" specified in "$json".',
        stackTrace: StackTrace.current,
      );
      throw ArgumentError(
        '❌ Invalid Json neither "directive" nor "promptTag" specified in "$json".',
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
