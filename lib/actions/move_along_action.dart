import 'package:storytrail/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';

class MoveAlongAction extends NpcAction {
  final List<LatLng> path;

  MoveAlongAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.path,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    print('${npc.name} starts moving along a path');
    npc.moveAlong(path);
    return true;
  }

  static MoveAlongAction actionFromJson(Map<String, dynamic> json) {
    final path = StoryLine.pathFromJson(json);
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(
      json,
    );
    return MoveAlongAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      path: path,
    );
  }

  static void register() {
    NpcAction.registerAction('moveAlong', MoveAlongAction.actionFromJson);
  }
}
