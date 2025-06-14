import 'package:aitrailsgo/gui/game_screen.dart';
import 'ui_intent.dart';

class SaveGameIntent extends UIIntent {

  SaveGameIntent();

  @override
  Future<void> call(GameScreenState state) async {
    state.saveGame();
  }
}
