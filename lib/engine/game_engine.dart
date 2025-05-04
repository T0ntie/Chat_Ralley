import 'dart:collection';

import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/notification_services.dart';

import 'story_line.dart';
import 'npc.dart';
import '../actions/npc_action.dart';
import 'hotspot.dart';

extension KeyNormalization on String {
  String get norm => toLowerCase().trim();
}

class GameEngine {
  static final GameEngine _instance = GameEngine._internal();

  factory GameEngine() => _instance;

  GameEngine._internal();

  static const double conversationDistance = 50.0;

  bool isTestSimimulationOn = false;

  StoryLine? storyLine;

  List<Npc> get npcs => storyLine?.npcs ?? [];

  List<Hotspot> get hotspots => storyLine?.hotspotsList ?? [];

  List<Item> get items => storyLine?.items ?? [];

  Map<String, bool> get flags => storyLine?.flags ?? {};

  final Map<String, List<(Npc, NpcAction)>> _signalSubscriptions = {};
  final Map<Npc, List<NpcAction>> _interactionSubscriptions = {};
  final Map<Npc, List<NpcAction>> _approachSubscriptions = {};
  final Map<Npc, List<NpcAction>> _initSubscriptions = {};
  final Map<String, List<(Npc, NpcAction)>> _hotspotSubscriptions = {};
  final Map<Npc, List<(NpcAction, int)>> _messageCountSubscriptions = {};

  final Queue<({Npc npc, NpcAction action})> _deferredActions = Queue();

  Hotspot? getHotspotByName(String hotspotName) {
    return storyLine?.hotspotMap[hotspotName];
  }

  Npc? getNpcByName(String npcName) {
    return storyLine?.npcs.firstWhere((npc) => npc.name == npcName);
  }

  Item? getItemByName(String itemName) {
    return items.firstWhere((item) => item.name == itemName);
  }

  bool hasNewItems() {
      return items.any((item) => item.isOwned && item.isNew);
  }
  void markAllItemsAsSeen() {
    for (final item in items) {
      if (item.isOwned && item.isNew) {
        item.isNew = false;
      }
    }
  }

  Map<String, List<(Npc, NpcAction)>> getActionsGroupedByTrigger() {
    final Map<String, List<(Npc, NpcAction)>> grouped = {};

    for (var (trigger, npc, action) in getAllRegisteredActionEntries()) {
      grouped.putIfAbsent(trigger, () => []).add((npc, action));
    }

    return grouped;
  }

  List<(String triggerType, Npc npc, NpcAction action)>
  getAllRegisteredActionEntries() {
    final List<(String, Npc, NpcAction)> result = [];

    // Signal: Map<String, List<(Npc, NpcAction)>>
    for (var entry in _signalSubscriptions.values) {
      for (var (npc, action) in entry) {
        result.add(('signal', npc, action));
      }
    }

    // Interaction: Map<Npc, List<NpcAction>>
    for (var entry in _interactionSubscriptions.entries) {
      for (var action in entry.value) {
        result.add(('interaction', entry.key, action));
      }
    }

    // Approach: Map<Npc, List<NpcAction>>
    for (var entry in _approachSubscriptions.entries) {
      for (var action in entry.value) {
        result.add(('approach', entry.key, action));
      }
    }

    // Init: Map<Npc, List<NpcAction>>
    for (var entry in _initSubscriptions.entries) {
      for (var action in entry.value) {
        result.add(('init', entry.key, action));
      }
    }

    // Hotspot: Map<String, List<(Npc, NpcAction)>>
    for (var entry in _hotspotSubscriptions.values) {
      for (var (npc, action) in entry) {
        result.add(('hotspot', npc, action));
      }
    }

    // MessageCount: Map<Npc, List<(NpcAction, int)>>
    for (var entry in _messageCountSubscriptions.entries) {
      for (var (action, _) in entry.value) {
        result.add(('message', entry.key, action));
      }
    }

    return result;
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
            _hotspotSubscriptions.putIfAbsent(hotspotName, () => []).add((
              npc,
              action,
            ));
            print('🧿 Registered hotspot action for ${hotspotName}');
            break;
          case TriggerType.message:
            final messageCount = action.trigger.value as int;
            _messageCountSubscriptions.putIfAbsent(npc, () => []).add((
              action,
              messageCount,
            ));
            print('💬 Registered message action for ${npc.name}');
        }
      }
    }
  }

  bool checkFlag(String flag) {
    if (!flags.containsKey(flag.norm)) {
      print('Unknown flag in checkFlag: ${flag.norm}');
    }
    return flags[flag.norm] ?? false;
  }

  void setFlag(String flag, bool value) {
    if (!flags.containsKey(flag.norm)) {
      print('New flag: ${flag.norm} set to $value');
    }
    flags[flag.norm] = value;
  }

  void setFlags(Map<String, bool> newFlags) {
    for (final entry in newFlags.entries) {
      flags[entry.key.norm] = entry.value;
    }
  }

  void showNotification(String notification) {
    FlushBarService().showFlushbar(title: "Ereignis", message: notification);
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
      if (action.defer) {
        print('⏸️ Verzögere Action ${action.runtimeType} für ${npc.name}');
        _deferredActions.add((npc: npc, action: action));
      } else {
        print('▶️ Action ${action.runtimeType} für ${npc.name} wird ausgeführt');
        action.invoke(npc);
      }
    }
  }

  void flushDeferredActions() {
    print('🔁 Verarbeite ${_deferredActions.length} verzögerte Actions...');
    while (_deferredActions.isNotEmpty) {
      final entry = _deferredActions.removeFirst();
      print('▶️ Action ${entry.action.runtimeType} für ${entry.npc.name} wird ausgeführt');
      entry.action.invoke(entry.npc);
    }
  }

  void _handleFlags(json) {
    Map<String, bool> newFlags = Map<String, bool>.from(json['flags']);
    newFlags.forEach((key, value) {
      flags[key.norm] =
          value; // Das Flag wird entweder hinzugefügt oder der Wert geändert
      print('🚩 Flag ${key.norm} set to ${value}');
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
        '🧿 Executing action for hotspot: ${hotspot.name} and npc: ${npc.name}',
      );
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
  }
}
