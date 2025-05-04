import 'npc_action.dart';
import '../engine/npc.dart';

class SpawnAction extends NpcAction{

  double distance;

  SpawnAction({required super.trigger, required super.conditions, super.notification, super.defer, required this.distance});

  @override
  void excecute(Npc npc) {
    print('${npc.name} spawns');
    npc.spawn(distance);
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