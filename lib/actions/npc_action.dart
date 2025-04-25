import 'package:hello_world/actions/behave_action.dart';
import 'package:hello_world/actions/spawn_action.dart';
import 'package:hello_world/actions/stop_moving_action.dart';
import 'package:hello_world/actions/talk_action.dart';

import 'walk_action.dart';
import 'appear_action.dart';
import 'reveal_action.dart';
import 'follow_action.dart';
import 'move_along_action.dart';
import '../engine/npc.dart';

enum TriggerType {signal, interaction, approach, init, hotspot, message}


class NpcActionTrigger {
  static const signalString = 'onSignal';
  static const interactionString = 'onInteraction';
  static const approachString = 'onApproach';
  static const initString = 'onInit';
  static const hotspotString = 'onHotspot';
  static const messageString = 'onMessageCount';

  final TriggerType type;
  final dynamic value;
  NpcActionTrigger ({required this.type, required this.value});

  static NpcActionTrigger npcActionTriggerfromJson(Map<String, dynamic> json) {
    if(json.containsKey(signalString)){
      return NpcActionTrigger(type: TriggerType.signal, value: json[signalString]);
    }else if (json.containsKey(interactionString)){
      return NpcActionTrigger(type: TriggerType.interaction, value: json[interactionString]);
    }else if (json.containsKey(approachString)){
      return NpcActionTrigger(type: TriggerType.approach, value: json[approachString]);
    } else if (json.containsKey(initString)){
      return NpcActionTrigger(type: TriggerType.init, value: json[initString]);
    } else if (json.containsKey(hotspotString)){
      return NpcActionTrigger(type: TriggerType.hotspot, value: json[hotspotString]);
    }else if (json.containsKey(messageString)) {
      return NpcActionTrigger(type: TriggerType.message, value: json[messageString]);
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

  static NpcAction fromJson(Map<String, dynamic> json) {
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
    BehaveAction.register();
    SpawnAction.register();
  }
}