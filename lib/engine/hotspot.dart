import 'dart:ui';

import 'package:storytrail/engine/game_engine.dart';

import '../engine/game_element.dart';
import '../engine/story_line.dart';
import 'package:latlong2/latlong.dart';


class Hotspot extends GameElement implements ProximityAware {
  double radius;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  Hotspot({
    required super.name,
    required super.position,
    required super.imageAsset,
    required this.radius,
    required super.isVisible,
    required super.isRevealed,
    required this.onEnter,
    required this.onExit,
  });

  static Hotspot fromJson(Map<String, dynamic> json) {
    final LatLng position = StoryLine.positionFromJson(json);
    String name = json['name'] as String;
    return Hotspot(
      name: name,
      radius: (json['radius'] as num?)?.toDouble() ?? 10.0,
      isVisible: json['visible'] as bool? ?? true,
      isRevealed: json['revealed'] as bool? ?? true,
      position: position,
      imageAsset: json['image'] as String? ?? GameElement.unknownImageAsset,
      onEnter: () => GameEngine().registerHotspot(name),
      onExit: () => print("Player left Hotspot $name."),
    );
  }

  double _distanceTo(LatLng point) {
    return const Distance().as(LengthUnit.Meter, position, point);
  }

  double get currentDistance {
    return _distanceTo(GameEngine().playerPosition);
  }

  bool _wasInRange = false;
  @override
  void updateProximity(LatLng playerPosition) {
    final inRange = _distanceTo(playerPosition) <= radius;

    if (inRange && !_wasInRange) {
      onEnter.call();
    } else if (!inRange && _wasInRange) {
      onExit.call();
    }

    _wasInRange = inRange;
  }
}