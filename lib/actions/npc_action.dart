import 'package:hello_world/actions/stop_moving_action.dart';

import 'walk_action.dart';
import 'appear_action.dart';
import 'reveal_action.dart';
import 'follow_action.dart';
import 'move_along_action.dart';
import '../engine/npc.dart';

abstract class NpcAction{
  final String signal;
  void invoke(Npc npc) {
    print('invoke für ${npc.name} aufgerufen');
  }

  NpcAction({required this.signal});

  static Future<NpcAction> fromJsonAsync(Map<String, dynamic> json) async{
    try {
      final actionType = json['invokeAction'];
      switch (actionType) {
        case 'walkTo':
          return WalkAction.fromJson(json);
        case 'follow':
          return FollowAction.fromJson(json);
        case 'appear':
          return AppearAction.fromJson(json);
        case 'reveal':
          return RevealAction.fromJson(json);
        case 'moveAlong':
          return MoveAlongAction.fromJson(json);
        case 'stopMoving':
          return StopMovingAction.fromJson(json);
        default:
        throw Exception('❌ Unknown action type in Action Json: $actionType');
      }
    }catch (e, stack) {
      print('❌ Fehler im Json der Action:\n$e\n$stack');
      rethrow;
    }
  }
}