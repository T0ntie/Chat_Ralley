import 'package:flutter/widgets.dart';
import 'package:hello_world/gui/action_observer.dart';
import 'package:hello_world/main.dart';

abstract class UIIntent {
  Future<void> call(BuildContext context);
}

void dispatchUIIntent(UIIntent intent) {
  final context = navigatorKey.currentContext;
  final isOnMainPage = ActionObserver().isOnMainPage;

  if (context != null && isOnMainPage) {
    intent.call(context);
  } else {
    //UiIntentQueue().enqueue(intent);
    print("Context nicht von der MainPage");
  }
}
