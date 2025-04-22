import 'package:hello_world/engine/game_element.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class AppearAction extends GameAction{

  AppearAction({required super.trigger});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    print('${element.name} appears');
    element.isVisible = true;
  }

  static AppearAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    return AppearAction(trigger: actionTrigger);
  }

  static void register() {
    GameAction.registerAction('appear', AppearAction.actionFromJson);
  }
}