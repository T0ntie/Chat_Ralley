import 'package:latlong2/latlong.dart';

import 'npc_action.dart';
import '../engine/npc.dart';

class MoveAlongAction extends NpcAction{

  //final double lat;
  //final double lng;
  final List<LatLng> path;

  MoveAlongAction({required String signal, required this.path}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} starts moving along a path');
    npc.moveAlong(path);
  }

  static MoveAlongAction fromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    final pathJson = json['params']['path'] as List;
    final path = pathJson.map((p) {
      final lat = p['lat'] as double;
      final lng = p['lng'] as double;
      return LatLng(lat, lng);
    }).toList();

    return MoveAlongAction(signal: signal, path: path);
  }
}