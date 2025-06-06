import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/npc.dart';
import 'package:storytrail/services/log_service.dart';

class SpawnAction extends NpcAction{

  double distance;

  SpawnAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.distance});

  @override
  Future<bool> excecute(Npc npc) async {
    log.i('🎬 ${npc.name} erscheint neben dem Spieler');
    npc.spawn(distance);
    return true;
  }

  static SpawnAction actionFromJson(Map<String, dynamic> json) {
    final (trigger, conditions, notification, defer) = NpcAction.actionFieldsFromJson(json);
    final distance = (json['distance'] as num?)?.toDouble() ?? 5.0;
    return SpawnAction(trigger: trigger, conditions: conditions, notification: notification, defer: defer, distance: distance);
  }
  static void register() {
    NpcAction.registerAction('spawn', SpawnAction.actionFromJson);
  }
}