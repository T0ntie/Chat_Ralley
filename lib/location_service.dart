import 'package:geolocator/geolocator.dart';

class LocationService {

  static Stream<Position>? _locationStream;

  static Future<void> initialize() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Ortungsdienste sind deaktiviert');
      throw Exception('❌ Ortungsdienste sind deaktiviert');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Standortberechtigung verweigert');
        throw Exception('❌ Standortberechtigung verweigert');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Standortberechtigung dauerhaft verweigert');
      throw Exception('❌ Standortberechtigung dauerhaft verweigert');
    }

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // liefert nur Updates bei >10m Bewegung
    );

    try {
      if (_locationStream == null) {
        _locationStream =  Geolocator.getPositionStream(locationSettings: locationSettings);
      }
    } catch (e, stack) {
      print('❌ Fehler beim Geolocator initialisieren:\n$e\n$stack');
      rethrow;
    }
  }
// Stream, um die Kompassrichtung zu abonnieren
  static Stream<Position> getPositionStream() {
    if (_locationStream == null) {
      print('❌ Kein LocationStream vorhanden');
      throw Exception('❌ Kein LocationStream vorhanden');
    }
    return _locationStream!;
  }
}