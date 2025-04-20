import 'package:latlong2/latlong.dart';

class Hotspot {
  String name;
  LatLng position;
  double radius;
  bool isVisible;
  Hotspot({required this.name, required this.position, required this.radius, required this.isVisible});

  static Hotspot fromJson(Map<String, dynamic> json) {
    //check vor valid position
    final pos = json['position'];
    if (pos is! Map || pos['lat'] == null || pos['lng'] == null) {
      throw FormatException('Ungültige Positionsdaten in stryline.jsn: $pos bei ${json['name']}');
    }
    return Hotspot(
      name: json['name'],
      radius: (json['radius'] as num).toDouble(),
      isVisible: json['visible'] as bool? ?? true,
      position: LatLng(
        (json['position']['lat'] as num).toDouble(),
        (json['position']['lng'] as num).toDouble(),
      ),
    );
  }
}