import 'story_line.dart';
import 'npc.dart';
import 'game_action.dart';
import 'hotspot.dart';
import 'game_element.dart';

class GameEngine {
  static final GameEngine _instance = GameEngine._internal(); //Singleton
  static GameEngine get instance => _instance;
  static final double conversationDistance = 50.0;

  late final StoryLine storyLine;

  List<Npc> get npcs => storyLine.npcs;
  List<Hotspot> get hotspots => storyLine.hotspots;
  final Map<String, List<(GameElement, GameAction)>> _signalSubscriptions = {};
  final Map<GameElement, List<GameAction>> _interactionSubscriptions = {};
  final Map<GameElement, List<GameAction>> _approachSubscriptions = {};
  final Map<GameElement, List<GameAction>> _initSubscriptions = {};

  GameEngine._internal();

  Future<void> initializeGame() async {
    GameAction.registerAllNpcActions();
    storyLine = await StoryLine.loadStoryLine();
    for (final element in [...npcs, ...hotspots]) {
      for (final action in element.actions) {
        switch (action.trigger.type) {
          case TriggerType.signal:
            final signal = action.trigger.value as String;
            _signalSubscriptions.putIfAbsent(signal, () => []).add((
              element,
              action,
            ));
            print('🔔 Registered signal action: "$signal" for ${element.name}');
            break;
          case TriggerType.interaction:
            _interactionSubscriptions.putIfAbsent(element, () => []).add(action);
            print('🗣️ Registered interaction action for ${element.name}');
            break;
          case TriggerType.approach:
            _approachSubscriptions.putIfAbsent(element, () => []).add(action);
            print('👣 Registered aproach action for ${element.name}');
            break;
          case TriggerType.init:
            _initSubscriptions.putIfAbsent(element, () => []).add(action);
            print('🚀 Registered init action for ${element.name}');
        }
      }
    }
  }

  void registerApproach(GameElement element) {
    final actions = _approachSubscriptions[element];
    if (actions != null) {
      for (final action in actions) {
        print('👣 Executing action for : ${element.name}');
        action.invoke(element);
      }
      _approachSubscriptions.remove(element);
    } else {
      print('👣 No approach actions registered for ${element.name}');
    }
  }
  void registerInteraction(GameElement element) {
    final actions = _interactionSubscriptions[element];
    if (actions != null) {
      for (final action in actions) {
        print('🗣️ Executing action for: ${element.name}');
        action.invoke(element);
      }
      _interactionSubscriptions.remove(element);
    } else {
      print('🗣️ No interaction actions registered for ${element.name}');
    }
  }

  void registerInitialization(){
    print ('🚀 Initialization registered!');
    for (final entry in _initSubscriptions.entries) {
      final GameElement element = entry.key;
      final List<GameAction> actions = entry.value;
      for(final action in actions) {
        action.invoke(element);
      }
      print(' Excecuting action for: ${element.name} ');
    }
  }

  void registerSignal(String signal) {
    print('Signal ${signal} registered!');
    final subscribers = _signalSubscriptions[signal];
    if (subscribers == null) {
      print('🔔 No subscribers for signal $signal.');
      return;
    }
    for (final (element, action) in subscribers) {
      print('🔔 Executing action for: ${element.name}');
      action.invoke(element); // vorausgesetzt, Action hat diese Methode
    }
  }
}
