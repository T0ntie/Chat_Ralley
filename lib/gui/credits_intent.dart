import 'package:flutter/material.dart';
import 'package:hello_world/gui/credits_screen.dart';
import 'package:hello_world/main.dart';
import 'ui_intent.dart';

class CreditsIntent extends UIIntent {

  CreditsIntent();

  @override
  Future<void> call(BuildContext context) async {

    print("Launching End-Screen....");
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => CreditsScreen(),
      ),
    );
  }
}
