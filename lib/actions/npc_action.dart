import 'package:flutter/material.dart';
import 'package:storytrail/actions/add_to_inventory_action.dart';
import 'package:storytrail/actions/behave_action.dart';
import 'package:storytrail/actions/end_game_action.dart';
import 'package:storytrail/actions/lead_action.dart';
import 'package:storytrail/actions/lead_along_action.dart';
import 'package:storytrail/actions/notify_action.dart';
import 'package:storytrail/actions/save_game_action.dart';
import 'package:storytrail/actions/scan_to_inventory_action.dart';
import 'package:storytrail/actions/set_flag_action.dart';
import 'package:storytrail/actions/show_hotspot_action.dart';
import 'package:storytrail/actions/reveal_hotspot_action.dart';
import 'package:storytrail/actions/spawn_action.dart';
import 'package:storytrail/actions/stop_moving_action.dart';
import 'package:storytrail/actions/stop_talking_action.dart';
import 'package:storytrail/actions/talk_action.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/story_journal.dart';

import 'package:storytrail/actions/walk_action.dart';
import 'package:storytrail/actions/appear_action.dart';
import 'package:storytrail/actions/reveal_action.dart';
import 'package:storytrail/actions/follow_action.dart';
import 'package:storytrail/actions/move_along_action.dart';
import 'package:storytrail/engine/npc.dart';

enum TriggerType {
  signal,
  interaction,
  approach,
  init,
  restore,
  hotspot,
  message,
}

extension TriggerTypeX on TriggerType {
  String get key {
    switch (this) {
      case TriggerType.signal: return 'onSignal';
      case TriggerType.interaction: return 'onInteraction';
      case TriggerType.approach: return 'onApproach';
      case TriggerType.init: return 'onInit';
      case TriggerType.restore: return 'onRestore';
      case TriggerType.hotspot: return 'onHotspot';
      case TriggerType.message: return 'onMessageCount';
    }
  }

  static bool isKnownKey(String key) =>
      TriggerType.values.any((t) => t.key == key);

  static TriggerType fromKey(String key) {
    return TriggerType.values.firstWhere(
      (e) => e.key == key,
      orElse:
          () => throw FormatException('❌ Unbekannter TriggerType-Key: $key'),
    );
  }
}

class NpcActionTrigger {
  final TriggerType type;
  final dynamic value;

  /*
  static const Map<String, TriggerType> _stringToTriggerType = {
    'onSignal': TriggerType.signal,
    'onInteraction': TriggerType.interaction,
    'onApproach': TriggerType.approach,
    'onInit': TriggerType.init,
    'onRestore': TriggerType.restore,
    'onHotspot': TriggerType.hotspot,
    'onMessageCount': TriggerType.message,
  };
*/

  /* @visibleForTesting
  static Map<String, TriggerType> get stringToTriggerTypeForTest =>
      Map.unmodifiable(_stringToTriggerType);
*/
  NpcActionTrigger({required this.type, required this.value});

  /*  static NpcActionTrigger npcActionTriggerfromJson(Map<String, dynamic> json) {
    for (final entry in _stringToTriggerType.entries) {
      if (json.containsKey(entry.key)) {
        return NpcActionTrigger(type: entry.value, value: json[entry.key]);
      }
    }
    throw FormatException('❌ Unbekannter Action Trigger in: $json');
  }*/

  factory NpcActionTrigger.fromJson(Map<String, dynamic> json) {
    final triggerEntry = json.entries.firstWhere(
      (e) => TriggerTypeX.isKnownKey(e.key),
      orElse:
          () => throw FormatException('❌ Kein gültiger Trigger-Key in: $json'),
    );

    return NpcActionTrigger(
      type: TriggerTypeX.fromKey(triggerEntry.key),
      value: triggerEntry.value,
    );
  }

  /*factory NpcActionTrigger.fromJson(Map<String, dynamic> json) {

    print("so sieht das trigger json aus: ${json.toString()}");

    final entry = _stringToTriggerType.entries.firstWhere(
          (e) => json.containsKey(e.key),
      orElse: () => throw FormatException('❌ Unbekannter Action Trigger in: $json'),
    );
    return NpcActionTrigger(type: entry.value, value: json[entry.key]);
  }
*/
}

abstract class NpcAction {
  final NpcActionTrigger trigger;
  final Map<String, bool> conditions;
  final String? notification;
  final bool defer;

  NpcAction({
    required this.trigger,
    required this.conditions,
    this.notification,
    this.defer = false,
  });

  static final Map<String, NpcAction Function(Map<String, dynamic>)>
  _actionRegistry = {};

  @visibleForTesting
  static Map<String, NpcAction Function(Map<String, dynamic>)>
  get actionRegistryForTest => Map.unmodifiable(_actionRegistry);

  static void registerAction(
    String type,
    NpcAction Function(Map<String, dynamic>) factory,
  ) {
    _actionRegistry[type] = factory;
  }

  Future<bool> invoke(Npc npc) async {
    /*
    Map<String, bool> flags = GameEngine().flags;


    print("Aktuelle Flags im GameEngine:");
    flags.forEach((key, value) {
      print("  $key: $value");
    });

    print("Aktuelle Items: ");
    for (final item in GameEngine().items) {
      print("Item: ${item.name}: owned: ${item.isOwned}");
    }

    print("Conditions für Invoke:");
    conditions.forEach((key, value) {
      print("-->  '$key': '$value'");
    });
*/

    bool allConditionsMet = conditions.entries.every((entry) {
      final key = entry.key;
      final expected = entry.value;

      if (key.startsWith('flag:')) {
        final flagName = key.substring(5);
        return GameEngine().checkFlag(flagName) == expected;
      } else if (key.startsWith('item:')) {
        final itemId = key.substring(5).trim();
/*
        print(
          "comparing item: $itemId ${GameEngine().ownsItem(itemId)} == $expected",
        );
*/
        return GameEngine().ownsItem(itemId) == expected;
      } else if (key.startsWith('npc:')){

        //print("-> key starts with npc: $key");
        final npcPart = key.substring(4).trim();
        //print("Part is : $npcPart");
        final segments = npcPart.split('.');
        //print("segments: $segments");
        if (segments.length == 2) {
         final npcId = segments[0];
         //print("npcId: $npcId");
         final propertyName = segments[1];
         //print("propertyName: $propertyName");
         final Npc? targetNpc = GameEngine().getNpcById(npcId);
         if (targetNpc != null) {
           final gameState = targetNpc.saveGameState();
           //print("gameState = $gameState");
           return gameState[propertyName] == expected;
         }
         else {
           print("while invoking no npc found with id: $npcId");
           return false;
         }
        }
        else {
          print("failed to parse conditions on key: $key");
          return false;
        }
      } else {
        print("condition key found with out prefix, key: $key");
        // Rückwärtskompatibel für alte Keys ohne Präfix
        return GameEngine().checkFlag(key) == expected;
      }
    });

    if (allConditionsMet) {
      bool result = await excecute(npc);
      //print("executed for: ${npc.name} notification: $notification");
      if (result && notification != null) {
        GameEngine().showNotification(notification!);
        //print("notifcation shown");
      }
      return result;
    }
    return false;
  }

  Future<bool> excecute(Npc npc);

  void log(String message) {
    StoryJournal().logAction(message);
  }

  static (NpcActionTrigger, Map<String, bool>, String?, bool)
  actionFieldsFromJson(Map<String, dynamic> json) {
    final trigger = NpcActionTrigger.fromJson(json);
    final conditions = conditionsFromJson(json);
    final notification =
        json.containsKey('notification')
            ? json['notification'] as String
            : null;
    final defer = json['defer'] == true;
    return (trigger, conditions, notification, defer);
  }

  static Map<String, bool> conditionsFromJson(Map<String, dynamic> json) {
    if (json.containsKey('conditions')) {
      final rawConditions = (json['conditions'] as Map<String, dynamic>);
      return {
        for (final entry in rawConditions.entries)
          entry.key: entry.value as bool,
      };
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
    NotifyAction.register();
    LeadAction.register();
    LeadAlongAction.register();
    ScanToInventoryAction.register();
    EndGameAction.register();
    SaveGameAction.register();
  }
}
