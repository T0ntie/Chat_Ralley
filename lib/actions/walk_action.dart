import 'package:latlong2/latlong.dart';

import 'action.dart';
import '../engine/npc.dart';

class WalkAction extends Action{

  final double lat;
  final double lng;

  WalkAction({required String signal, required this.lat, required this.lng}) : super(signal: signal);

  @override
  void invoke(Npc npc) {
    super.invoke(npc);
    print('${npc.name} starts walking to ${lat}, ${lng}');
    npc.moveTo(LatLng(lat, lng));
  }

  static WalkAction fromJson(Map<String, dynamic> json) {
    final signal = json['onSignal'];
    final lat = json['params']['lat'];
    final lng = json['params']['lng'];

    return WalkAction(signal: signal, lat: lat, lng: lng);
  }
}