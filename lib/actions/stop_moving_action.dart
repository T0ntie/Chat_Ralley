import 'package:hello_world/engine/game_element.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class StopMovingAction extends GameAction{

  StopMovingAction({required super.trigger});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} stops moving');
      element.stopMoving();
    } else {
      print('⚠️ StoipMovingAction can only be applied to Npc, but got ${element.runtimeType}');
    }
  }

  static StopMovingAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    return StopMovingAction(trigger: actionTrigger);
  }

  static void register() {
    GameAction.registerAction('stopMoving', StopMovingAction.actionFromJson);
  }
}