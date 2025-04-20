import 'story_line.dart';
import 'npc.dart';
import '../actions/npc_action.dart';

class GameEngine {
  static final GameEngine _instance = GameEngine._internal(); //Singleton
  static GameEngine get instance => _instance;

  late final StoryLine storyLine;

  List<Npc> get npcs => storyLine.npcs;
  final Map<String, List<(Npc, NpcAction)>> _signalSubscriptions = {};
  final Map<Npc, List<NpcAction>> _interactionSubscriptions = {};

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
        }
      }
    }
  }

  void registerInteraction(Npc npc) {
    final actions = _interactionSubscriptions[npc];
    if (actions != null) {
      for (final action in actions) {
        action.invoke(npc);
      }
    } else {
      print('ℹ️ No interaction actions registered for ${npc.name}');
    }
  }

  void registerSignal(String signal) {
    print('Signal ${signal} registered!');
    final subscribers = _signalSubscriptions[signal];
    if (subscribers == null) {
      print('No subscribers for signal $signal.');
      return;
    }
    for (final (npc, action) in subscribers) {
      print('Executing action for NPC: ${npc.name}');
      action.invoke(npc); // vorausgesetzt, Action hat diese Methode
    }
  }
}
