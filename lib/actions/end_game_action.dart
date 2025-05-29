import 'package:storytrail/gui/credits_intent.dart';
import 'package:storytrail/gui/ui_intent.dart';

import 'npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class EndGameAction extends NpcAction {

  EndGameAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
  });

  @override
  Future<bool> excecute(Npc npc) async {

    print("Trying to end the game");

    dispatchUIIntent(
      CreditsIntent(),
    );
    return true;
  }

  static EndGameAction actionFromJson(Map<String, dynamic> json) {
    final (
      trigger,
      conditions,
      notification,
      defer,
    ) = NpcAction.actionFieldsFromJson(json);
    return EndGameAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
    );
  }

  static void register() {
    NpcAction.registerAction(
      'endGame',
      EndGameAction.actionFromJson,
    );
  }
}
