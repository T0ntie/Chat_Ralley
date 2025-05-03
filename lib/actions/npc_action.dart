import 'package:hello_world/actions/add_to_inventory_action.dart';
import 'package:hello_world/actions/behave_action.dart';
import 'package:hello_world/actions/set_flag_action.dart';
import 'package:hello_world/actions/show_hotspot_action.dart';
import 'package:hello_world/actions/reveal_hotspot_action.dart';
import 'package:hello_world/actions/spawn_action.dart';
import 'package:hello_world/actions/stop_moving_action.dart';
import 'package:hello_world/actions/stop_talking_action.dart';
import 'package:hello_world/actions/talk_action.dart';
import 'package:hello_world/engine/game_engine.dart';

import 'walk_action.dart';
import 'appear_action.dart';
import 'reveal_action.dart';
import 'follow_action.dart';
import 'move_along_action.dart';
import '../engine/npc.dart';

enum TriggerType {signal, interaction, approach, init, hotspot, message}

class NpcActionTrigger {
  final TriggerType type;
  final dynamic value;

  static const Map<String, TriggerType> _stringToTriggerType = {
    'onSignal': TriggerType.signal,
    'onInteraction': TriggerType.interaction,
    'onApproach': TriggerType.approach,
    'onInit': TriggerType.init,
    'onHotspot': TriggerType.hotspot,
    'onMessageCount': TriggerType.message,
  };

  NpcActionTrigger ({required this.type, required this.value});

  static NpcActionTrigger npcActionTriggerfromJson(Map<String, dynamic> json) {
    for (final entry in _stringToTriggerType.entries) {
      if (json.containsKey(entry.key)) {
        return NpcActionTrigger(type: entry.value, value: json[entry.key]);
      }
    }
    throw FormatException('❌ Unbekannter Action Trigger in: $json');
  }}

abstract class NpcAction{
  final NpcActionTrigger trigger;
  final Map<String, bool> conditions;
  final String? notification;

  static final Map<String, NpcAction Function(Map<String, dynamic>)> _actionRegistry = {};
  static void registerAction(
      String type,
      NpcAction Function(Map<String, dynamic>) factory,
      ) {
    _actionRegistry[type] = factory;
  }

  void invoke(Npc npc)
  {
    Map<String, bool> flags = GameEngine().flags;

    print("Aktuelle Flags im GameEngine:");
    flags.forEach((key, value) {
      print("  $key: $value");
    });

    print("Conditions für Invoke:");
    conditions.forEach((key, value) {
      print("  $key: $value");
    });


    bool allConditionsMet = conditions.keys
        .where(flags.containsKey)
        .every((key) => conditions[key] == flags[key]);  // Werte vergleichen

    if (allConditionsMet) {
      excecute(npc);
      if (notification != null) {
        GameEngine().showNotification(notification!);
      }
    }
  }

  void excecute(Npc npc);

  NpcAction({required this.trigger, required this.conditions, this.notification});

  static  (NpcActionTrigger, Map<String, bool>, String?) actionFieldsFromJson (Map<String, dynamic> json) {
    final trigger = NpcActionTrigger.npcActionTriggerfromJson(json);
    final conditions = conditionsFromJson(json);
    final notification = json.containsKey('notification') ? json['notification'] as String : null;
    return (trigger, conditions, notification);
  }

  static Map<String, bool> conditionsFromJson(Map<String, dynamic> json) {
    if (json.containsKey('conditions')) {
      return (json['conditions'] as Map<String, dynamic>).cast<String, bool>();
    }
    return {};
  }
  
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
    ShowHotspotAction.register();
    RevealHotspotAction.register();
    StopTalkingAction.register();
    SetFlagAction.register();
    AddToInventoryAction.register();
  }
}