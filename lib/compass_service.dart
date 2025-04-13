// lib/compass_service.dart
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

class CompassService {

  // Stream, das die Kompassrichtung liefert
  static Stream<double>? _compassStream;

  // Methode zur Initialisierung des Kompass-Streams
  static Future<void> initialize() async {
    if (_compassStream == null) {
      final rawStream = FlutterCompass.events;
      if (rawStream != null) {
        _compassStream = rawStream.map((event) => event?.heading ?? 0.0);
      } else {
        _compassStream =
        const Stream.empty(); // Fallback für Geräte ohne Sensor
      }
    }
  }
  // Stream, um die Kompassrichtung zu abonnieren
  static Stream<double> getCompassDirection() {
    return _compassStream ?? const Stream.empty();
  }
}