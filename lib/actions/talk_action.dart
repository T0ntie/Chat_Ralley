import 'package:hello_world/engine/game_element.dart';
import '../engine/game_action.dart';
import '../engine/npc.dart';

class TalkAction extends GameAction{
  String triggerMessage;
  TalkAction({required super.trigger, required this.triggerMessage});

  @override
  void invoke(GameElement element) {
    super.invoke(element);
    if (element is Npc) {
      print('${element.name} starts talking');
      element.talk(triggerMessage);
    } else {
      print('⚠️ TalkAction can only be applied to Npc, but got ${element.runtimeType}');
    }
  }

  static TalkAction actionFromJson(Map<String, dynamic> json) {
    GameActionTrigger actionTrigger = GameActionTrigger.npcActionTriggerfromJson(json);
    final triggerMessage = json['params']['trigger'];
    return TalkAction(trigger: actionTrigger, triggerMessage: triggerMessage);
  }

  static void register() {
    GameAction.registerAction('talk', TalkAction.actionFromJson);
  }
}