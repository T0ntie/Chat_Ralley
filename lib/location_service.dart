// lib/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


class LocationService {

  // Stream, das die Kompassrichtung liefert
  static Stream<Position>? _locationStream;

  static Future<void> initialize() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Ortungsdienste sind deaktiviert');
      return ;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Standortberechtigung verweigert");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Standortberechtigung dauerhaft verweigert");
      return ;
    }

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // liefert nur Updates bei >10m Bewegung
    );

    if (_locationStream == null) {
      _locationStream =  Geolocator.getPositionStream(locationSettings: locationSettings);
      print("PositionStream inititialized");
    }
  }
// Stream, um die Kompassrichtung zu abonnieren
  static Stream<Position> getPositionStream() {
    if (_locationStream == null) {
      print("achtung locationStream is null!!!!!!!!");
    }
    return _locationStream ?? const Stream.empty();
  }

  /*
  static Future<LatLng> getCurrentLocation() async {
    LatLng resultPosition = LatLng(51.5074, -0.1278); // Beispiel für London

    Position position = await Geolocator.getCurrentPosition();
    resultPosition = LatLng(position.latitude, position.longitude);
    return resultPosition;
  }*/
}