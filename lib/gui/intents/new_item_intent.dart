import 'package:aitrailsgo/gui/game_screen.dart';
import 'package:aitrailsgo/services/log_service.dart';
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