import 'npc_action.dart';
import '../engine/npc.dart';

class StopMovingAction extends NpcAction{

  StopMovingAction({required String signal}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} stops');
    npc.stopMoving();
  }

  static StopMovingAction actionFromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    return StopMovingAction(signal: signal);
  }
  static void register() {
    NpcAction.registerAction('stopMoving', StopMovingAction.actionFromJson);
  }
}