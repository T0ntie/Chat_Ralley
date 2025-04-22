import 'package:hello_world/engine/game_element.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class SpawnAction extends GameAction{

  SpawnAction({required super.trigger});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} spawns');
      element.spawn();
    } else {
      print('⚠️ SpawnAction can only be applied to Npc, but got ${element.runtimeType}');
    }
  }

  static SpawnAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    return SpawnAction(trigger: actionTrigger);
  }
  static void register() {
    GameAction.registerAction('spawn', SpawnAction.actionFromJson);
  }
}