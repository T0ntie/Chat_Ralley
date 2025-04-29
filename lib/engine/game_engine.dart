import 'package:another_flushbar/flushbar_route.dart';
import 'package:flutter/material.dart';
import 'package:hello_world/app_resources.dart';
import 'package:hello_world/gui/notification_services.dart';

import 'story_line.dart';
import 'npc.dart';
import '../actions/npc_action.dart';
import 'hotspot.dart';

class GameEngine {

  static final GameEngine _instance = GameEngine._internal();
  factory GameEngine() => _instance;
  GameEngine._internal();

  static final double conversationDistance = 50.0;
  bool isTestSimimulationOn = false;

  late final StoryLine storyLine;

  List<Npc> get npcs => storyLine.npcs;

  List<Hotspot> get hotspots => storyLine.hotspotsList;

  Map <String, bool> get flags => storyLine.flags;

  final Map<String, List<(Npc, NpcAction)>> _signalSubscriptions = {};
  final Map<Npc, List<NpcAction>> _interactionSubscriptions = {};
  final Map<Npc, List<NpcAction>> _approachSubscriptions = {};
  final Map<Npc, List<NpcAction>> _initSubscriptions = {};
  final Map<String, List<(Npc, NpcAction)>> _hotspotSubscriptions = {};
  final Map<Npc, List<(NpcAction, int)>> _messageCountSubscriptions = {};

  Hotspot? getHotspotByName(String hotspotName) {
    return storyLine.hotspotMap[hotspotName];
  }

  Future<void> initializeGame() async {
    NpcAction.registerAllNpcActions();
    storyLine = await StoryLine.loadStoryLine();
    for (final npc in npcs) {
      for (final action in npc.actions) {
        switch (action.trigger.type) {
          case TriggerType.signal:
            final signal = action.trigger.value as String;
            _signalSubscriptions.putIfAbsent(signal, () => []).add((
            npc,
            action,
            ));
            print('🔔 Registered signal action: "$signal" for ${npc.name}');
            break;
          case TriggerType.interaction:
            _interactionSubscriptions.putIfAbsent(npc, () => []).add(action);
            print('🗣️ Registered interaction action for ${npc.name}');
            break;
          case TriggerType.approach:
            _approachSubscriptions.putIfAbsent(npc, () => []).add(action);
            print('👣 Registered aproach action for ${npc.name}');
            break;
          case TriggerType.init:
            _initSubscriptions.putIfAbsent(npc, () => []).add(action);
            print('🚀 Registered init action for ${npc.name}');
            break;
          case TriggerType.hotspot:
            final hotspotName = action.trigger.value as String;
            _hotspotSubscriptions.putIfAbsent(hotspotName, () => []).add(
                (npc, action));
            print('🧿 Registered hotspot action for ${hotspotName}');
            break;
          case TriggerType.message:
            final messageCount = action.trigger.value as int;
            _messageCountSubscriptions.putIfAbsent(npc, () => []).add(
                (action, messageCount));
            print('💬 Registered message action for ${npc.name}');
        }
      }
    }
  }

  bool checkFlag(String flag) {
    if (!flags.containsKey(flag)) {
      print('Unknown flag in checkFlag: $flag');
    }
    return flags[flag] ?? false;
  }

  void setFlag(String flag, bool value) {
    if (!flags.containsKey(flag)) {
      print('New flag: $flag set to $value');
    }
    flags[flag] = value;
  }

  void showNotification(String notification) {
    FlushBarService().showFlushbar(title: "Event", message: notification);
  }


void registerApproach(Npc npc) {
  final actions = _approachSubscriptions[npc];
  if (actions != null) {
    for (final action in actions) {
      print('👣 Executing action for NPC: ${npc.name}');
      action.invoke(npc);
    }
    _approachSubscriptions.remove(npc);
  } else {
    print('👣 No approach actions registered for ${npc.name}');
  }
}

void registerInteraction(Npc npc) {
  final actions = _interactionSubscriptions[npc];
  if (actions != null) {
    for (final action in actions) {
      print('🗣️ Executing action for NPC: ${npc.name}');
      action.invoke(npc);
    }
    _interactionSubscriptions.remove(npc);
  } else {
    print('🗣️ No interaction actions registered for ${npc.name}');
  }
}

void registerInitialization() {
  print('🚀 Initialization registered!');
  for (final entry in _initSubscriptions.entries) {
    final Npc npc = entry.key;
    final List<NpcAction> actions = entry.value;
    for (final action in actions) {
      action.invoke(npc);
    }
    print(' Excecuting action for NPC: ');
  }
}

void registerSignal(Map<String, dynamic> json) {
  print('Signal ${json} registered!');
  if (json.containsKey('signal')) {
    _handleSignals(json);
  }
  if (json.containsKey('flags')) {
    _handleFlags(json);
  }
}

void _handleSignals(json) {
  final signalString = json['signal'] as String;
  final subscribers = _signalSubscriptions[signalString];
  if (subscribers == null) {
    print('🔔 No subscribers for signal $signalString.');
    return;
  }
  for (final (npc, action) in subscribers) {
    print('🔔 Executing action for NPC: ${npc.name}');
    action.invoke(npc);
  }
}

void _handleFlags(json) {
  Map<String, bool> newFlags = Map<String, bool>.from(json['flags']);
  newFlags.forEach((key, value) {
    flags[key] =
        value; // Das Flag wird entweder hinzugefügt oder der Wert geändert
    print('🚩 Flag ${key} set to ${value}');
  });
}

void registerHotspot(Hotspot hotspot) {
  print('🧿 Hotspot registered: ${hotspot.name}');
  final subscribers = _hotspotSubscriptions[hotspot.name];
  if (subscribers == null) {
    print('🧿 No subscribers for hotspot ${hotspot.name}');
    return;
  }
  for (final (npc, action) in subscribers) {
    print(
        '🧿 Executing action for hotspot: ${hotspot.name} and npc: ${npc.name}');
    action.invoke(npc);
  }
}

void registerMessage(Npc npc, int count) {
  print('💬 Message for ${npc.name} registered');
  for (final entry in _messageCountSubscriptions.entries) {
    final Npc npc = entry.key;
    final List<(NpcAction, int)> actionsEntries = entry.value;
    for (final actionEntry in actionsEntries) {
      final (NpcAction action, int messageCount) = actionEntry;
      if (messageCount == count) {
        print('💬 Executing action for ${npc.name}');
        action.invoke(npc);
      }
    }
  }
}}