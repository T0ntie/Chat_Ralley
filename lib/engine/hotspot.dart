import 'dart:ui';

import 'package:storytrail/engine/game_engine.dart';

import 'package:storytrail/engine/game_element.dart';
import 'package:storytrail/engine/story_line.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/services/log_service.dart';

class Hotspot extends GameElement with HasGameState implements ProximityAware {
  double radius;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  Hotspot({
    required super.id,
    required super.name,
    required super.position,
    required super.imageAsset,
    required this.radius,
    required super.isVisible,
    required super.isRevealed,
    required this.onEnter,
    required this.onExit,
  }) {
    registerSelf();
  }

  static Hotspot fromJson(Map<String, dynamic> json) {
    final LatLng position = StoryLine.positionFromJson(json);
    String name = json['name'] as String;
    String id = json['id'] as String;
    return Hotspot(
      id: id,
      name: name,
      radius: (json['radius'] as num?)?.toDouble() ?? 10.0,
      isVisible: json['visible'] as bool? ?? true,
      isRevealed: json['revealed'] as bool? ?? true,
      position: position,
      imageAsset: json['image'] as String? ?? GameElement.unknownImageAsset,
      onEnter: () => GameEngine().registerHotspot(id),
      onExit: () => log.d("Spieler hat Hotspot $name verlassen."),
    );
  }

  @override
  void loadGameState(Map<String, dynamic> json) {
    isVisible = json['isVisible'];
    isRevealed = json['isRevealed'];
  }

  @override
  Map<String, dynamic> saveGameState() => {
    'id': id,
    'isVisible': isVisible,
    'isRevealed': isRevealed,
  };

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
