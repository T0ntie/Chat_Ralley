import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class MoveAlongAction extends NpcAction {
  final List<LatLng> path;

  MoveAlongAction({
    required super.trigger,
    required super.conditions,
    required this.path,
  });

  @override
  void excecute(Npc npc) {
    print('${npc.name} starts moving along a path');
    npc.moveAlong(path);
  }

  static MoveAlongAction actionFromJson(Map<String, dynamic> json) {
    final path = StoryLine.pathFromJson(json);
    return MoveAlongAction(
      trigger: NpcActionTrigger.npcActionTriggerfromJson(json),
      conditions: NpcAction.conditionsFromJson(json),
      path: path,
    );
  }

  static void register() {
    NpcAction.registerAction('moveAlong', MoveAlongAction.actionFromJson);
  }
}
