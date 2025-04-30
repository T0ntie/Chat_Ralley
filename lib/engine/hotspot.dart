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
    required super.isRevealed,
  });

  static Hotspot fromJson(Map<String, dynamic> json) {
    final LatLng position = StoryLine.positionFromJson(json);
    return Hotspot(
      name: json['name'],
      radius: (json['radius'] as num).toDouble(),
      isVisible: json['visible'] as bool? ?? true,
      isRevealed: json['revealed'] as bool? ?? true,
      position: position,
    );
  }

  bool contains(LatLng point) {
    double distance = const Distance().as(LengthUnit.Meter, position, point);
    return distance <= radius;
  }
}