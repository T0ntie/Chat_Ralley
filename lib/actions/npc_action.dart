import 'package:hello_world/actions/stop_moving_action.dart';
import 'package:hello_world/actions/talk_action.dart';

import 'walk_action.dart';
import 'appear_action.dart';
import 'reveal_action.dart';
import 'follow_action.dart';
import 'move_along_action.dart';
import '../engine/npc.dart';

enum TriggerType {signal, interaction}

class NpcActionTrigger {
  final TriggerType type;
  final dynamic value;
  NpcActionTrigger ({required this.type, required this.value});

  static NpcActionTrigger npcActionTriggerfromJson(Map<String, dynamic> json) {
    if(json.containsKey('onSignal')){
      return NpcActionTrigger(type: TriggerType.signal, value: json['onSignal']);
    }else if (json.containsKey('onInteraction')){
      return NpcActionTrigger(type: TriggerType.interaction, value: json['onInteraction']);
    }
    throw FormatException("Unbekannter Action Trigger in:$json");
  }
}

abstract class NpcAction{
  final NpcActionTrigger trigger;

  static final Map<String, NpcAction Function(Map<String, dynamic>)> _actionRegistry = {};
  static void registerAction(
      String type,
      NpcAction Function(Map<String, dynamic>) factory,
      ) {
    _actionRegistry[type] = factory;
  }

  void invoke(Npc npc) {
    //print('invoke für ${npc.name} aufgerufen');
  }

  NpcAction({required this.trigger});

  static NpcAction fromJsonAsync(Map<String, dynamic> json) {
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
  }
}