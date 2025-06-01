import 'package:flutter/material.dart';
import 'package:storytrail/gui/game_screen.dart';
import 'package:storytrail/gui/credits_screen.dart';
import 'package:storytrail/main.dart';
import 'package:storytrail/services/log_service.dart';
import 'ui_intent.dart';

class CreditsIntent extends UIIntent {

  CreditsIntent();

  @override
  Future<void> call(GameScreenState state) async {

    log.i("🎨 Starte credits screen");
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => CreditsScreen(),
      ),
    );
  }
}
