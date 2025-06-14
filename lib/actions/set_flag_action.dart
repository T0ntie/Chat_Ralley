import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/services/log_service.dart';

import 'npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';

class SetFlagAction extends NpcAction {
  Map<String, bool> flags;

  SetFlagAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.flags,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC "${npc.name}" hat die folgenden Flags gesetzt: "$flags"');
    GameEngine().setFlags(flags);
    return true;
  }

  static SetFlagAction actionFromJson(Map<String, dynamic> json) {
    final flags = flagsFromJson(json);
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(
      json,
    );
    return SetFlagAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      flags: flags,
    );
  }
  static Map<String, bool> flagsFromJson(Map<String, dynamic> json) {
    if (json.containsKey('flags')) {
      return (json['flags'] as Map<String, dynamic>).cast<String, bool>();
    }
    return {};
  }

  static void register() {
    NpcAction.registerAction('setflag', SetFlagAction.actionFromJson);
  }
}