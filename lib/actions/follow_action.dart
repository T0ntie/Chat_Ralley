
import 'package:hello_world/engine/game_element.dart';

import '../engine/game_action.dart';
import '../engine/npc.dart';

class FollowAction extends GameAction{

  FollowAction({required super.trigger});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} starts following you');
      element.startFollowing();
    } else {
      print('⚠️ FollowAction can only be applied to Npc, but got ${element.runtimeType}');
    }
  }


  static FollowAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    return FollowAction(trigger: actionTrigger);
  }
  
  static void register() {
    GameAction.registerAction('follow', FollowAction.actionFromJson);
  }
}