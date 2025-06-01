import 'package:geolocator/geolocator.dart';
import 'package:storytrail/services/log_service.dart';

class LocationService {

  static Stream<Position>? _locationStream;

  static Future<void> initialize() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log.e('❌ Geolocator is not enabled.', stackTrace: StackTrace.current);
      throw Exception('❌ Geolocator is not enabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log.e('❌ Location permissions denied.', stackTrace: StackTrace.current);
        throw Exception('❌ Location permissions denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      log.e('❌ Location permissions permanently denied.', stackTrace: StackTrace.current);
      throw Exception('❌ Location permissions permanently denied.');
    }

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // liefert nur Updates bei >5m Bewegung
    );

    try {
      _locationStream ??= Geolocator.getPositionStream(locationSettings: locationSettings);
    } catch (e, stackTrace) {
      log.e('❌ Failed to initialize geolocator.', stackTrace: stackTrace);
      rethrow;
    }
  }

  static Stream<Position>? get stream => _locationStream;

  static void clear() => _locationStream = null;
}