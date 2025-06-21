import 'package:aitrailsgo/engine/story_line.dart';
import 'package:latlong2/latlong.dart';

import 'package:aitrailsgo/actions/npc_action.dart';
import 'package:aitrailsgo/engine/npc.dart';
import 'package:aitrailsgo/services/log_service.dart';

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
    double lat =  path.last.latitude;
    double lng = path.last.longitude;
    log.i('🎬 NPC ${npc.name} führt den Spieler einen Pfad entlang nach $lat, $lng');
    npc.leadAlong(path);
    jlog("${npc.name} führt den Spieler einen Pfad entlang nach $lat, $lng", credits: false);
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