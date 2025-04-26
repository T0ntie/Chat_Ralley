import 'package:latlong2/latlong.dart';

class GameElement {

  String name;
  LatLng position;
  bool isVisible;

  GameElement({
    required this.name,
    required this.position,
    required this.isVisible,
  });

  void appear() {
    isVisible = true;
  }
}