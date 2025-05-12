import 'package:flutter/material.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/main.dart';

class ActionObserver extends NavigatorObserver {

  static final ActionObserver _instance = ActionObserver._internal();
  ActionObserver._internal();

  factory ActionObserver() => _instance;

  bool isOnMainPage = false;

//  final List<Route> _pageStack = [];

/*
  void _logStack(String context) {
    final names = _pageStack.map((r) => r.settings.name ?? 'unnamed').join(', ');
    print("📚 Stack after $context [${_pageStack.length}]: [$names]");
  }
*/

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    final routeName = route.settings.name;
    if (routeName == '/') {
      isOnMainPage = true;
    } else {
      isOnMainPage = false;
    }

/*

    if (route is PageRoute) {
      _pageStack.add(route);
      print("⬆️ PUSHED PageRoute: ${route.settings.name ?? 'unnamed'}"  );
      _logStack("PUSH PageRoute");
    } else {
      print("📥 PUSHED (non-PageRoute): ${route.runtimeType}");
      _logStack("PUSH non-PageRoute");
    }
*/
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

/*
    if (route is PageRoute) {
      _pageStack.remove(route);
      print("⬇️ POPPED PageRoute: ${route.settings.name ?? 'unnamed'}");
      _logStack("POPP PageRoute");
    } else {
      print("📤 POPPED (non-PageRoute): ${route.runtimeType}");
      _logStack("POPP non-PageRoute");
    }

    print(" Did POPP -----------------------> previousRoute: ${previousRoute?.settings.name ?? 'unnamed'}");
*/

    final routeName = previousRoute?.settings.name;
    print("POPP, zurück auf der Mainpage: ${routeName =='/'}, gekommen von einer echten Seite: ${route is PageRoute}");

    isOnMainPage = (routeName == '/');

    if (routeName =='/' && route is PageRoute) {
      final context = navigator!.context;
      WidgetsBinding.instance.addPostFrameCallback((_) async{
        print("flushing deferred Actions now");
        await GameEngine().flushDeferredActions(navigator!.context);
        homePageKey.currentState?.checkForNewItemsWithDelay();
      });
    }
  }
}
