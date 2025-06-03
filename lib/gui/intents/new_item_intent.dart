import 'package:storytrail/engine/hotspot.dart';
import 'package:storytrail/gui/camera_flight.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'package:storytrail/services/log_service.dart';
import 'ui_intent.dart';

class NewItemIntent extends UIIntent {

  NewItemIntent();

  @override
  @override
  Future<void> call(GameScreenState state) async {
    log.i('🎨 Zeige das neue Item an');
    state.checkForNewItemsWithDelay();
  }
}