import 'package:latlong2/latlong.dart';
import 'package:storytrail/engine/game_engine.dart';

class Trail {
  final String trailId;
  final String title;
  final String label;
  final LatLng baseLocation;
  final String coverImage;

  Trail({
    required this.trailId,
    required this.title,
    required this.label,
    required this.baseLocation,
    required this.coverImage,
  });

  static Trail fromJson(Map<String, dynamic> json) {
    return Trail(
      trailId: json['trailId'],
      label: json['label'],
      title: json['title'],
      coverImage: json['coverImage'],
      baseLocation: _latLngFromJson(json['baseLocation']),
    );
  }

  static LatLng _latLngFromJson(Map<String, dynamic> json) {
    if (json.containsKey('lat') && json.containsKey('lng')) {
      return LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
    }
    throw FormatException("Missing or invalid Lat/Lng in $json");
  }

  double get currentDistance {
    return Distance().as(
      LengthUnit.Meter,
      baseLocation,
      GameEngine().playerPosition,
    );
  }
}
