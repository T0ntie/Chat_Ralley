import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../engine/item.dart';
import '../gui/chat/radio_chat_page.dart';
import '../services/gpt_utilities.dart';

typedef ItemUseCallback =
    Future<void> Function(BuildContext context, Item item);

class ItemCallbacks {
  static final Map<String, ItemUseCallback> useCallbackMap = {
    'radio': ItemCallbacks.openRadioChat,
    'show': ItemCallbacks.showItem,
  };

  static Future<void> openRadioChat(BuildContext context, Item item) async {
    item.npc.behave("[FUNK EIN]");
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RadioChatPage(npc: item.npc)),
    );
    item.npc.behave("[FUNK AUS]");
  }

  static Future<void> showItem(BuildContext context, Item item) async {
    if (item.npc.isInCommunicationDistance) {
      item.npc.talk(
        "[Der Spieler zeigt dir folgenden Gegenstand: ${item.name}",
      );
      String message = await GptUtilities.buildGrammaticalSentence(
        subject: "Du",
        predicate: "zeigst",
        akkusativeObject: item.name,
        dativeObject: item.npc.displayName,
      );
      GameEngine().showNotification(message);
    }
    else {
      GameEngine().showNotification("${item.npc.displayName} ist zu weit weg.");
    }

  }
}
