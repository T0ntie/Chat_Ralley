import 'package:hello_world/actions/npc_action.dart';
import 'package:latlong2/latlong.dart';

class GameElement {

  String name;
  LatLng position;
  bool isVisible;

  List<NpcAction> actions = []; //fixme doch in die NPC Klasse verschieben?

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