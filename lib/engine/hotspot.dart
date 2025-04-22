import 'package:hello_world/engine/game_element.dart';
import 'package:latlong2/latlong.dart';
import 'game_action.dart';

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
    //check vor valid position
    final pos = json['position'];
    if (pos is! Map || pos['lat'] == null || pos['lng'] == null) {
      throw FormatException('Ungültige Positionsdaten in stryline.jsn: $pos bei ${json['name']}');
    }
    final actionsJson = json['actions'] as List? ?? [];
    final actions = actionsJson.map((a) => GameAction.fromJson(a)).toList();
    return Hotspot(
      name: json['name'],
      radius: (json['radius'] as num).toDouble(),
      isVisible: json['visible'] as bool? ?? true,
      position: LatLng(
        (json['position']['lat'] as num).toDouble(),
        (json['position']['lng'] as num).toDouble(),
      ),
      actions: actions,
    );
  }
}