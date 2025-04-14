import 'npc.dart';

class Conversation {
  final NPC npc; // Der NPC, mit dem der User chattet
  final List<ChatMessage> messages = []; // Liste von Nachrichten

  Conversation(this.npc);

  void addMessage(ChatMessage message) {
    messages.add(message);
  }

  List<ChatMessage> getMessages() {
    return messages;
  }
}

class ChatMessage {
  final String text;
  final bool fromUser;

  ChatMessage({required this.text, required this.fromUser});
}
