import 'package:hello_world/actions/npc_action.dart';
import 'package:hello_world/engine/game_element.dart';
import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';


class Hotspot extends GameElement{
  double radius;

  Hotspot({
    required super.name,
    required super.position,
    required this.radius,
    required super.isVisible,
    required super.actions,
  });

  static Hotspot fromJson(Map<String, dynamic> json) {
    final LatLng position = StoryLine.positionFromJson(json);
    final actionsJson = json['actions'] as List? ?? [];
    final actions = actionsJson.map((a) => NpcAction.fromJson(a)).toList();
    return Hotspot(
      name: json['name'],
      radius: (json['radius'] as num).toDouble(),
      isVisible: json['visible'] as bool? ?? true,
      position: position,
      actions: actions,//fixme actions in hotspots?
    );
  }

  bool contains(LatLng point) {
    double distance = const Distance().as(LengthUnit.Meter, position, point);
    return distance <= radius;
  }
}