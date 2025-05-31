import 'package:flutter/material.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'package:storytrail/gui/credits_screen.dart';
import 'package:storytrail/main.dart';
import 'ui_intent.dart';

class SaveGameIntent extends UIIntent {

  SaveGameIntent();

  @override
  Future<void> call(GameScreenState state) async {
    print("Sielspeichern aus Intent");
    state.saveGame();
    print("erledigt");
  }
}
