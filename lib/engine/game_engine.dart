import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:storytrail/engine/trail.dart';
import 'package:storytrail/services/firebase_serice.dart';
import '../engine/item.dart';
import '../engine/moving_controller.dart';
import '../gui/notification_services.dart';
import 'package:latlong2/latlong.dart';

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

  static const double conversationDistance = 5.0;

  bool isGPSSimulating = false;
  LatLng? _lastSimulatedPosition;

  final PlayerMovementController _playerMovementController =
      PlayerMovementController(startPosition: PlayerMovementController.simHome);

  PlayerMovementController? get playerMovementController =>
      _playerMovementController;

  String? trailId;
  List<Trail> trailsList = [];


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

    late LatLng _realGpsPosition = PlayerMovementController.simHome; //just a initilizer
  LatLng get playerPosition {
    return isGPSSimulating
        ? _playerMovementController.currentPosition
        : _realGpsPosition;
  }

  void setRealGpsPositionAndNotify(LatLng newPosition) {
    _realGpsPosition = newPosition;
    _playerPositionUpdated(newPosition);
  }

  set playerPosition(LatLng newPosition) {
    if (isGPSSimulating) {
      _playerMovementController.teleportTo(newPosition);
    } else {
      _realGpsPosition = newPosition;

      _playerPositionUpdated(newPosition);
    }
  }

  late LatLng gpsPosition;

  void updatePlayerPositionSimulated() {
    if (!isGPSSimulating) return;
    final newPosition = _playerMovementController.updatePosition();

    if (_lastSimulatedPosition == newPosition) {
      return;
    }
    _lastSimulatedPosition = newPosition;
    _playerPositionUpdated(newPosition);
  }

  void _playerPositionUpdated(LatLng newPosition) {
    final allProximityAware = <ProximityAware>[
      ...npcs,
      ...hotspots,
    ];

    for (final entity in allProximityAware) {
      entity.updateProximity(newPosition);
    }
  }

  void updateAllNpcPositions() {
    for (final npc in npcs) {
      npc.movementController.updatePosition();
    }
  }

  Npc? getNpcByName(String npcName) {
    final npcs = storyLine?.npcs;
    if (npcs == null) return null;

    for (final npc in npcs) {
      if (npc.name == npcName) return npc;
    }
    return null;
  }

  String npcImagePath(Npc npc) {
    return "$trailId/${npc.displayImageAsset}";
  }

  String itemIconPath(Item item){
    return "$trailId/${item.iconAsset}";
  }

  String creditsImagePath() {
    return "$trailId/${storyLine?.creditsImage}";
  }

  String creditsTextPath() {
    return "$trailId/${storyLine?.creditsText}";
  }

  String hotspotImagePath(Hotspot hotspot) {
    return "$trailId/${hotspot.displayImageAsset}";
  }

  Item? getItemByName(String itemName) {
    try {
      return items.firstWhere((item) => item.name == itemName);
    } catch (e) {
      return null;
    }
  }

  bool ownsItem(String itemName) {
    Item? item = getItemByName(itemName);
    return item?.isOwned ?? false;
  }

  bool hasNewItems() {
    return items.any((item) => item.isOwned && item.isNew);
  }

  bool hasScannableItems() {
    return items.any((item) => item.isScannable);
  }

  List<Item> getScannableItems() {
    return items.where((item) => item.isScannable).toList();
  }

  void markAllItemsAsSeen() {
    for (final item in items) {
      if (item.isOwned && item.isNew) {
        item.isNew = false;
      }
    }
  }

  Future<void> loadTrails() async {
    final json = await FirebaseHosting.loadJsonFromUrl("trails.json");
    final List<dynamic> list = json['trails']; // <=== Zugriff auf die Liste
    trailsList =
        list
            .cast<Map<String, dynamic>>() // typisieren
            .map((e) => Trail.fromJson(e)) // umwandeln
            .toList(); // Liste erzeugen
  }

  Future<void> loadSelectedTrail(String trailId) async {
    this.trailId = trailId;
    NpcAction.registerAllNpcActions();
    storyLine = await StoryLine.loadStoryLine(trailId);
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
            print('🧿 Registered hotspot action for $hotspotName');
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

  Future<void> _runActions(
    Map<Npc, List<NpcAction>> map,
    Npc npc,
    String logPrefix,
  ) async {
    final actions = map[npc];
    final remaining = <NpcAction>[];

    if (actions != null) {
      for (final action in actions) {
        final didRun = await action.invoke(npc);
        print(
          '$logPrefix ${action.runtimeType} for ${npc.name} executed: $didRun',
        );
        if (!didRun) remaining.add(action);
      }
      if (remaining.isEmpty) {
        map.remove(npc);
      } else {
        map[npc] = remaining;
      }
    } else {
      print('$logPrefix No actions for ${npc.name}');
    }
  }

  Future<void> _runHotspotActions(String hotspotName) async {
    final subscribers = _hotspotSubscriptions[hotspotName];
    if (subscribers == null) {
      print('🧿 No actions registered for hotspot $hotspotName');
      return;
    }

    final remaining = <(Npc, NpcAction)>[];

    for (final (npc, action) in subscribers) {
      final didRun = await action.invoke(npc);
      print(
        '🧿 Action ${action.runtimeType} for ${npc.name} at $hotspotName: $didRun',
      );
      if (!didRun) remaining.add((npc, action));
    }

    if (remaining.isEmpty) {
      _hotspotSubscriptions.remove(hotspotName);
    } else {
      _hotspotSubscriptions[hotspotName] = remaining;
    }
  }

  Future<void> registerApproach(Npc npc) =>
      _runActions(_approachSubscriptions, npc, '👣');

  Future<void> registerInteraction(Npc npc) =>
      _runActions(_interactionSubscriptions, npc, '🗣️');

  Future<void> registerHotspot(String hotspot) async {
    await _runHotspotActions(hotspot);
  }

  Future<void> registerInitialization() async {
    print('🚀 Initialization registered!');
    for (final entry in _initSubscriptions.entries.toList()) {
      final Npc npc = entry.key;
      final List<NpcAction> actions = entry.value;
      for (final action in actions) {
        final didRun = await action.invoke(npc);
        print(
          '🚀 Action ${action.runtimeType} for NPC: ${npc.name} executed: $didRun',
        );
      }
      _initSubscriptions.remove(entry.key); // ✅ funktioniert jetzt
    }
  }

  Future<void> registerSignal(Map<String, dynamic> json) async {
    print('Signal $json registered!');
    if (json.containsKey('signal')) {
      await _handleSignals(json);
    }
    if (json.containsKey('flags')) {
      _handleFlags(json);
    }
  }

  Future<void> _handleSignals(json) async {
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
        print(
          '▶️ Action ${action.runtimeType} für ${npc.name} wird ausgeführt',
        );
        await action.invoke(npc);
      }
    }
  }

  Future<void> flushDeferredActions(
    BuildContext context, {
    VoidCallback? onFlushed,
  }) async {
    print('🔁 Verarbeite ${_deferredActions.length} verzögerte Actions...');
    while (_deferredActions.isNotEmpty) {
      final entry = _deferredActions.removeFirst();
      print(
        '▶️ Action ${entry.action.runtimeType} für ${entry.npc.name} wird ausgeführt',
      );
      await entry.action.invoke(entry.npc);
    }
  }

  void _handleFlags(json) {
    Map<String, bool> newFlags = Map<String, bool>.from(json['flags']);
    newFlags.forEach((key, value) {
      flags[key.norm] =
          value; // Das Flag wird entweder hinzugefügt oder der Wert geändert
      print('🚩 Flag ${key.norm} set to $value');
    });
  }

  void registerMessage(Npc npc, int count) async {
    print('💬 Message for ${npc.name} registered');
    for (final entry in _messageCountSubscriptions.entries.toList()) {
      final Npc npc = entry.key;
      final List<(NpcAction, int)> actionsEntries = entry.value;
      for (final actionEntry in actionsEntries) {
        final (NpcAction action, int messageCount) = actionEntry;
        if (messageCount == count) {
          print('💬 Executing action for ${npc.name}');
          await action.invoke(npc);
        }
      }
    }
  }

  void reset() {
    _signalSubscriptions.clear();
    _interactionSubscriptions.clear();
    _approachSubscriptions.clear();
    _initSubscriptions.clear();
    _hotspotSubscriptions.clear();
    _messageCountSubscriptions.clear();
    _deferredActions.clear();
    storyLine = null;
    _lastSimulatedPosition = null;
  }
}

class GameEngineDebugger {
  static Map<String, List<(Npc, NpcAction)>>? _actionsGroupedByTrigger;

  static Map<String, List<(Npc, NpcAction)>> getActionsGroupedByTrigger() {
    if (_actionsGroupedByTrigger != null) {
      return _actionsGroupedByTrigger!;
    }

    final Map<String, List<(Npc, NpcAction)>> grouped = {};

    for (var (trigger, npc, action) in _getAllRegisteredActionEntries()) {
      grouped.putIfAbsent(trigger, () => []).add((npc, action));
    }

    _actionsGroupedByTrigger = grouped;
    return grouped;
  }

  static List<(String triggerType, Npc npc, NpcAction action)>
  _getAllRegisteredActionEntries() {
    final List<(String, Npc, NpcAction)> result = [];

    // Signal: Map<String, List<(Npc, NpcAction)>>
    for (var entry in GameEngine()._signalSubscriptions.values) {
      for (var (npc, action) in entry) {
        result.add(('signal', npc, action));
      }
    }

    // Interaction: Map<Npc, List<NpcAction>>
    for (var entry in GameEngine()._interactionSubscriptions.entries) {
      for (var action in entry.value) {
        result.add(('interaction', entry.key, action));
      }
    }

    // Approach: Map<Npc, List<NpcAction>>
    for (var entry in GameEngine()._approachSubscriptions.entries) {
      for (var action in entry.value) {
        result.add(('approach', entry.key, action));
        //print("Approach-Action added to registered Actions: ${action.runtimeType}");
      }
    }

    // Init: Map<Npc, List<NpcAction>>
    for (var entry in GameEngine()._initSubscriptions.entries) {
      for (var action in entry.value) {
        result.add(('init', entry.key, action));
      }
    }

    // Hotspot: Map<String, List<(Npc, NpcAction)>>
    for (var entry in GameEngine()._hotspotSubscriptions.values) {
      for (var (npc, action) in entry) {
        result.add(('hotspot', npc, action));
      }
    }

    // MessageCount: Map<Npc, List<(NpcAction, int)>>
    for (var entry in GameEngine()._messageCountSubscriptions.entries) {
      for (var (action, _) in entry.value) {
        result.add(('message', entry.key, action));
      }
    }
    return result;
  }
}
