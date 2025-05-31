import 'package:storytrail/gui/intents/credits_intent.dart';
import 'package:storytrail/gui/intents/save_game_intent.dart';
import 'package:storytrail/gui/intents/ui_intent.dart';

import 'npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class SaveGameAction extends NpcAction {

  SaveGameAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
  });

  @override
  Future<bool> excecute(Npc npc) async {

    print("Trying to save the game");


    dispatchUIIntent(
      SaveGameIntent(),
    );
    return true;
  }

  static SaveGameAction actionFromJson(Map<String, dynamic> json) {
    final (
      trigger,
      conditions,
      notification,
      defer,
    ) = NpcAction.actionFieldsFromJson(json);
    return SaveGameAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
    );
  }

  static void register() {
    NpcAction.registerAction(
      'saveGame',
      SaveGameAction.actionFromJson,
    );
  }
}
