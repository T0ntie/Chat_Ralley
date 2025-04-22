import 'package:latlong2/latlong.dart';
import 'game_action.dart';

class GameElement {

  String name;
  LatLng position;
  bool isVisible;

  List<GameAction> actions = [];

  GameElement({
    required this.name,
    required this.position,
    required this.isVisible,
    required this.actions,
  });

  void appear() {
    isVisible = true;
  }
}