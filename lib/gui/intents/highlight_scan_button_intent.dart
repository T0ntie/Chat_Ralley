import 'package:storytrail/engine/hotspot.dart';
import 'package:storytrail/gui/camera_flight.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'package:storytrail/services/log_service.dart';
import 'ui_intent.dart';

class HighlightScanButtonIntent extends UIIntent {

  HighlightScanButtonIntent();

  @override
  @override
  Future<void> call(GameScreenState state) async {
    log.i('🎨 Animiere den ScanButton als Hinweis');
    state.highlightScanButton();
  }
}