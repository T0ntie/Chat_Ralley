
import 'npc_action.dart';
import '../engine/npc.dart';

class FollowAction extends NpcAction{

  FollowAction({required String signal}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} starts following you');
    npc.startFollowing();
  }

  static FollowAction fromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    return FollowAction(signal: signal);
  }
}