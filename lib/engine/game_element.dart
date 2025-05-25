import 'package:latlong2/latlong.dart';

class GameElement {

  String name;
  LatLng position;
  bool isVisible;
  bool isRevealed;
  String imageAsset;

  static final String unknownImageAsset = "images/unknown.png";

  GameElement({
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

abstract class ProximityAware {
  void updateProximity(LatLng playerPosition);
}
