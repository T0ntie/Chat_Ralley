// lib/compass_service.dart
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

import 'package:aitrailsgo/services/log_service.dart';

class CompassService {

  // Stream, das die Kompassrichtung liefert
  static Stream<double>? _compassStream;

  // Methode zur Initialisierung des Kompass-Streams
  static Future<void> initialize() async {
    if (_compassStream == null) {
      final rawStream = FlutterCompass.events;
      if (rawStream != null) {
        _compassStream = rawStream.map((event) => event.heading ?? 0.0);
      } else {
        log.e('❌ Failed to initialize compass stream.', stackTrace: StackTrace.current);
          throw Exception('❌ Failed to initialize compass stream.');
      }
    }
  }
  // Stream, um die Kompassrichtung zu abonnieren
  static Stream<double> getCompassDirection() {
    return _compassStream ?? const Stream.empty();
  }
}