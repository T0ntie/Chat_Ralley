import 'package:hello_world/engine/game_element.dart';
import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';


class Hotspot extends GameElement{
  double radius;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London;

  Hotspot({
    required super.name,
    required super.position,
    required super.imageAsset,
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
      imageAsset: json['image'] as String? ?? GameElement.unknownImageAsset,
    );
  }
  double get currentDistance {
    return Distance().as(LengthUnit.Meter, position, playerPosition);
  }

  bool contains(LatLng point) { //fixme implizite PlayerPosition
    playerPosition = point;
    double distance = const Distance().as(LengthUnit.Meter, position, point);
    return distance <= radius;
  }
}