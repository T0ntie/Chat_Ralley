import 'story_line.dart';
import 'npc.dart';
import '../actions/npc_action.dart';
import 'hotspot.dart';

class GameEngine {
  static final GameEngine _instance = GameEngine._internal(); //Singleton
  static GameEngine get instance => _instance;
  static final double conversationDistance = 50.0;

  late final StoryLine storyLine;

  List<Npc> get npcs => storyLine.npcs;
  List<Hotspot> get hotspots => storyLine.hotspots;
  final Map<String, List<(Npc, NpcAction)>> _signalSubscriptions = {};
  final Map<Npc, List<NpcAction>> _interactionSubscriptions = {};
  final Map<Npc, List<NpcAction>> _approachSubscriptions = {};
  final Map<Npc, List<NpcAction>> _initSubscriptions = {};
  final Map<String, List<(Npc, NpcAction)>> _hotspotSubscriptions = {};

  GameEngine._internal();

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
            _hotspotSubscriptions.putIfAbsent(hotspotName, () => []).add((npc, action));
            print('🧿 Registered hotspot action for ${hotspotName}');
        }
      }
    }
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

  void registerInitialization(){
    print ('🚀 Initialization registered!');
    for (final entry in _initSubscriptions.entries) {
      final Npc npc = entry.key;
      final List<NpcAction> actions = entry.value;
      for(final action in actions) {
        action.invoke(npc);
      }
      print(' Excecuting action for NPC: ');
    }
  }

  void registerSignal(String signal) {
    print('Signal ${signal} registered!');
    final subscribers = _signalSubscriptions[signal];
    if (subscribers == null) {
      print('🔔 No subscribers for signal $signal.');
      return;
    }
    for (final (npc, action) in subscribers) {
      print('🔔 Executing action for NPC: ${npc.name}');
      action.invoke(npc); // vorausgesetzt, Action hat diese Methode
    }
  }
  void registerHotspot(Hotspot hotspot) {
    print('🧿 Hotspot registered: ${hotspot.name}');
    final subscribers = _hotspotSubscriptions[hotspot.name];
    if (subscribers == null){
      print('🧿 No subscribers for hotspot ${hotspot.name}');
      return;
    }
    for (final (npc, action) in subscribers){
      print('🧿 Executing action for hotspot: ${hotspot.name} and npc: ${npc.name}');
      action.invoke(npc);
    }
  }
}
