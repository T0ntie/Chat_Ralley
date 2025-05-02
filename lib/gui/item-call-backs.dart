import 'package:flutter/material.dart';
import 'package:hello_world/engine/conversation.dart';
import 'package:hello_world/engine/item.dart';
import 'package:hello_world/gui/chat/chat_page.dart';
import 'package:hello_world/gui/chat/radio_chat_page.dart';

typedef ItemUseCallback = Future<void> Function(BuildContext context, Item item);

class ItemCallbacks
{
  static final Map<String, ItemUseCallback> useCallbackMap = {
    'radio' : ItemCallbacks.openRadioChat,
  };

  static Future<void> openRadioChat(BuildContext context, Item item) async {
    item.npc.behave("[FUNK EIN]");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RadioChatPage(npc: item.npc),
      ),
    );
    item.npc.behave("[FUNK AUS]");
  }
}