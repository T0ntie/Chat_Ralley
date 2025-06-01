import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';



class LogService {
  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.warning : Level.trace,
    printer: SimplePrinter(colors: true),
    /*PrettyPrinter(
      printEmojis: true,
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 100,
    ),*/
  );


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

//alias
typedef log = LogService;


