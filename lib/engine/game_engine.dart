import 'story_line.dart';
import 'npc.dart';
import '../actions/npc_action.dart';

class GameEngine
{
  static final GameEngine _instance = GameEngine._internal(); //Singleton
  static GameEngine get instance => _instance;

  late final StoryLine storyLine;
  List<Npc> get npcs => storyLine.npcs;
  final Map<String, List<(Npc, NpcAction)>> _signalSubscriptions = {};

  GameEngine._internal();

  Future<void> initializeGame() async {
    NpcAction.registerAllNpcActions();
    storyLine = await StoryLine.loadStoryLine();
    for (final npc in npcs) {
      for (final action in npc.actions) {
        _signalSubscriptions.putIfAbsent(action.signal, () => []).add((npc, action));
        print('Action subscription done: ${action.signal} for ${npc.name}');
      }
    }
  }

  void registerSignal( String signal) {
    print ('Signal ${signal} registered!');
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


