import 'package:hello_world/actions/spawn_action.dart';
import 'package:hello_world/actions/stop_moving_action.dart';
import 'package:hello_world/actions/talk_action.dart';

import '../actions/walk_action.dart';
import '../actions/appear_action.dart';
import '../actions/reveal_action.dart';
import '../actions/follow_action.dart';
import '../actions/move_along_action.dart';
import 'game_element.dart';

enum TriggerType {signal, interaction, approach, init}

class GameActionTrigger {
  final TriggerType type;
  final dynamic value;
  GameActionTrigger ({required this.type, required this.value});

  static GameActionTrigger npcActionTriggerfromJson(Map<String, dynamic> json) {
    if(json.containsKey('onSignal')){
      return GameActionTrigger(type: TriggerType.signal, value: json['onSignal']);
    }else if (json.containsKey('onInteraction')){
      return GameActionTrigger(type: TriggerType.interaction, value: json['onInteraction']);
    }else if (json.containsKey('onApproach')){
      return GameActionTrigger(type: TriggerType.approach, value: json['onApproach']);
    } else if (json.containsKey('onInit')){
      return GameActionTrigger(type: TriggerType.init, value: json['onInit']);
    }
    throw FormatException("Unbekannter Action Trigger in:$json");
  }
}

abstract class GameAction{
  final GameActionTrigger trigger;

  static final Map<String, GameAction Function(Map<String, dynamic>)> _actionRegistry = {};
  static void registerAction(
      String type,
      GameAction Function(Map<String, dynamic>) factory,
      ) {
    _actionRegistry[type] = factory;
  }

  void invoke(GameElement element) {
    //print('invoke für ${npc.name} aufgerufen');
  }

  GameAction({required this.trigger});

  static GameAction fromJson(Map<String, dynamic> json) {
    final actionType = json['invokeAction'];
    final factory = _actionRegistry[actionType];

    if (factory == null) {
      throw Exception('❌ Unknown action type in storyline.jnsn: $actionType');
    }
    return factory(json);
  }

  static void registerAllNpcActions() {
    WalkAction.register();
    FollowAction.register();
    AppearAction.register();
    RevealAction.register();
    MoveAlongAction.register();
    StopMovingAction.register();
    TalkAction.register();
    SpawnAction.register();
  }
}