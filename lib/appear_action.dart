import 'action.dart';
import 'npc.dart';

class AppearAction extends Action{

  AppearAction({required String signal}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} appears');
    npc.isVisible = true;
  }

  static AppearAction fromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    return AppearAction(signal: signal);
  }
}