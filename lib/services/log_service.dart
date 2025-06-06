import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';



class LogService {
  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.warning : Level.trace,
    //printer:SimplePrinter(colors: true),
    printer: PrettyPrinter(
    printEmojis: true,        // Emojis behalten für visuelle Orientierung
    methodCount: 0,           // Keine Methoden bei normalen Logs
    errorMethodCount: 5,      // Stacktrace nur bei Fehlern
    lineLength: 120,          // Längere Zeilen, um Zeilenumbrüche zu vermeiden
    colors: true,
    noBoxingByDefault: true,  // <<< WICHTIG: Kein ASCII-Rahmen!
  ),  );


  static void d(dynamic message) => _logger.d('[storytrail] $message');

  static void i(dynamic message) => _logger.i('[storytrail] $message');

  static void w(dynamic message) => _logger.w('[storytrail] $message');

  static void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(
      '[storytrail] $message',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

// alias
// ignore: camel_case_types
typedef log = LogService;


