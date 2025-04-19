import 'npc_action.dart';
import '../engine/npc.dart';

class RevealAction extends NpcAction{

  RevealAction({required String signal}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} reveals');
    npc.reveal();
  }

  static RevealAction fromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    return RevealAction(signal: signal);
  }
}