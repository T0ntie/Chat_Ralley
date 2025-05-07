import 'package:flutter/material.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/chat/radio_chat_page.dart';
import 'package:hello_world/services/chat_service.dart';

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
    item.npc.behave(
      "[Der Spieler zeigt dir folgenden Gegenstand: ${item.name}",
    );
    String message = await ChatService.generateItemMessage(item.npcName, item.name);
    GameEngine().showNotification(message);
  }

}
