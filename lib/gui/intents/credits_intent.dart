import 'package:flutter/material.dart';
import 'package:aitrailsgo/gui/game_screen.dart';
import 'package:aitrailsgo/gui/credits_screen.dart';
import 'package:aitrailsgo/main.dart';
import 'package:aitrailsgo/services/log_service.dart';
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
