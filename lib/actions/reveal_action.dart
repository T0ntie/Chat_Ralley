import 'package:hello_world/engine/game_element.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class RevealAction extends GameAction{

  RevealAction({required super.trigger});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} reveals');
      element.reveal();
    } else {
      print('⚠️ Reveal can only be applied to Npc, but got ${element.runtimeType}');
    }
  }

  static RevealAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    return RevealAction(trigger: actionTrigger);
  }
  static void register() {
    GameAction.registerAction('reveal', RevealAction.actionFromJson);
  }
}