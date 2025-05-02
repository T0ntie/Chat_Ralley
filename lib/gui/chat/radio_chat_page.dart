import 'package:flutter/material.dart';
import 'package:hello_world/engine/npc.dart';
import 'chat_page.dart';
import '../../engine/conversation.dart';

class RadioChatPage extends StatelessWidget {
  final Npc npc;

  const RadioChatPage({super.key, required this.npc});

  @override
  Widget build(BuildContext context) {
    return ChatPage(
      npc: npc,
      medium: Medium.radio,
    );
  }
}
