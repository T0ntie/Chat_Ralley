import 'package:latlong2/latlong.dart';

class GameElement {

  String name;
  LatLng position;
  bool isVisible;
  bool isRevealed;

  GameElement({
    required this.name,
    required this.position,
    required this.isVisible,
    required this.isRevealed,
  });

  void appear() {
    isVisible = true;
  }
}