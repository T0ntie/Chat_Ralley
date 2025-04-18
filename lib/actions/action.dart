import 'walk_action.dart';
import 'appear_action.dart';
import '../engine/npc.dart';

abstract class Action{
  final String signal;
  void invoke(Npc npc) {
    print('invoke für ${npc.name} aufgerufen');
  }

  Action({required this.signal});

  static Future<Action> fromJsonAsync(Map<String, dynamic> json) async{
    try {
      final actionType = json['invokeAction'];
      switch (actionType) {
        case 'walkTo':
          return WalkAction.fromJson(json);
        case 'appear':
          return AppearAction.fromJson(json);
        default:
        throw Exception('❌ Unknown action type in Action Json: $actionType');
      }
    }catch (e, stack) {
      print('❌ Fehler im Json der Action:\n$e\n$stack');
      rethrow;
    }
  }
}