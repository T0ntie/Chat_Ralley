import 'package:latlong2/latlong.dart';
import 'package:storytrail/engine/game_engine.dart';

class GameElement with HasIdentity {

  @override
  String id;
  @override
  String name;
  LatLng position;
  bool isVisible;
  @override
  bool isRevealed;
  String imageAsset;

  static final String unknownImageAsset = "images/unknown.png";

  GameElement({
    required this.id,
    required this.name,
    required this.position,
    required this.imageAsset,
    required this.isVisible,
    required this.isRevealed,
  });

  String get displayImageAsset {
    //return isRevealed ? imageAsset : unknownImageAsset;
    return imageAsset;
  }

  void appear() {
    isVisible = true;
  }
}

mixin HasIdentity {
 String get id;
 String get name;
 bool get isRevealed;
 set isRevealed (bool value);

 void reveal() => isRevealed = true;
}

mixin HasPosition
{
  LatLng get position;
  bool get isVisible;
  set isVisible (bool value);
  String get imageAsset;
}

mixin HasGameState {
  String get id;
  void registerSelf() {
    GameEngine().registerGameState(this);
  }
  void loadGameState(Map<String, dynamic> json);
  Map<String, dynamic> saveGameState();
}

abstract class ProximityAware {
  void updateProximity(LatLng playerPosition);
}

