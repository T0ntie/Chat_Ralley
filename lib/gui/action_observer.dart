import 'package:flutter/material.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/main.dart';

class ActionObserver extends NavigatorObserver {

  static final ActionObserver _instance = ActionObserver._internal();
  ActionObserver._internal();

  factory ActionObserver() => _instance;

  bool isOnMainPage = false;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    final routeName = route.settings.name;
    if (routeName == '/') {
      isOnMainPage = true;
    } else {
      isOnMainPage = false;
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    final routeName = previousRoute?.settings.name;
    //print("POPP, zurück auf der Mainpage: ${routeName =='/'}, gekommen von einer echten Seite: ${route is PageRoute}");
    //print("📤 POPPED (non-PageRoute): ${route.runtimeType}");
    isOnMainPage = (routeName == '/');

    if (routeName =='/' && route is PageRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) async{
        await GameEngine().flushDeferredActions(navigator!.context);
        homePageKey.currentState?.checkForNewItemsWithDelay();
      });
    }
  }
}