import 'npc_action.dart';
import '../engine/npc.dart';

class AppearAction extends NpcAction{

  AppearAction({required String signal}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} appears');
    npc.isVisible = true;
  }

  static AppearAction actionFromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    return AppearAction(signal: signal);
  }
  static void register() {
    NpcAction.registerAction('appear', AppearAction.actionFromJson);
  }

}