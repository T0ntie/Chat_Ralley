import 'package:flutter/widgets.dart';
import 'package:aitrailsgo/services/location_service.dart';
import 'package:aitrailsgo/services/log_service.dart';

class LocationStreamManager with WidgetsBindingObserver {
  static final LocationStreamManager _instance = LocationStreamManager._internal();
  factory LocationStreamManager() => _instance;
  LocationStreamManager._internal();

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _startStream();
  }

  void _startStream() async {
    try {
      await LocationService.initialize();
      log.d("📡 LocationStream gestartet");
    } catch (e, stackTrace) {
      log.e("❌ Failed to start location stream.", error: e, stackTrace: stackTrace);
      assert(true, "❌ Failed to start location stream.");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.d("📡 App resumed restart location stream.");
      LocationService.clear();
      _startStream();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}