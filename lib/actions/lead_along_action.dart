import 'package:storytrail/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class LeadAlongAction extends NpcAction {
  final List<LatLng> path;

  LeadAlongAction({
    required super.trigger,
    required super.conditions,
    super.notification,
    super.defer,
    required this.path,
  });

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 NPC ${npc.name} führt den Spieler einen Pfad entlang.');
    npc.leadAlong(path);
    jlog("${npc.name} führt den Spieler an einem bestimmten Ort.");
    return true;
  }

  static LeadAlongAction actionFromJson(Map<String, dynamic> json) {
    final path = StoryLine.pathFromJson(json);
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(
      json,
    );
    return LeadAlongAction(
      trigger: trigger,
      conditions: conditions,
      notification: notification,
      defer: defer,
      path: path,
    );
  }

  static void register() {
    NpcAction.registerAction('leadAlong', LeadAlongAction.actionFromJson);
  }
}