import 'package:flutter/widgets.dart';
import 'package:storytrail/services/location_service.dart';

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
      debugPrint("📍 LocationStream gestartet");
    } catch (e) {
      debugPrint("❌ Fehler beim Starten des LocationStream: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 App resumed – Standortstream ggf. neu starten");
      LocationService.clear();
      _startStream();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
