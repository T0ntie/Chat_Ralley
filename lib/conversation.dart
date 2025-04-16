import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'chat_service.dart';
import 'npc.dart';

class Conversation {
  final NPC npc; // Der NPC, mit dem der User chattet
  final List<ChatMessage> _messages = []; // Liste von Nachrichten

  Conversation(this.npc) {
    addSystemMessage(npc.prompt);
}

  List<ChatMessage> getMessages() {
    return List.unmodifiable(_messages); // Unmodifiable List zurückgeben
  }
  List<ChatMessage> getVisibleMessages() {
    return List.unmodifiable(_messages.where((msg) => !msg.fromSystem));
  }

  void addUserMessage(String message)
  {
    _messages.add(ChatMessage(text: message, chatRole: ChatRole.user));
  }
  void addAssistantMessage(String message)
  {
    _messages.add(ChatMessage(text: message, chatRole: ChatRole.assistant));
  }
  void addSystemMessage(String message)
  {
    _messages.add(ChatMessage(text: message, chatRole: ChatRole.system));
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  Future<String> ask() async
  {
    //return await ChatService.sendMessage("Das ist ein Test, sag einfach test succeeded als antwort");
    return await ChatService.processMessages(_toOpenAIMessages ());
  }

  List<Map<String, String>> _toOpenAIMessages() {
    return _messages.map((msg) => {
      'role': msg.getRoleString(),
      'content': msg.text,
    }).toList();
  }
}

enum ChatRole {user, assistant, system}

  class ChatMessage {
  static const userRole = "user";
  static const assistantRole = "assistant";
  static const systemRole = "system";

  final String text;

  final ChatRole chatRole;
  ChatMessage({required this.text, required this.chatRole});

  // Getter für "fromUser"
  bool get fromUser => chatRole == ChatRole.user;
  bool get fromAssistant => chatRole == ChatRole.assistant;
  bool get fromSystem => chatRole == ChatRole.system;

  String getRoleString()
  {
    switch (chatRole){
      case ChatRole.user: return userRole;
      case ChatRole.assistant: return assistantRole;
      case ChatRole.system: return systemRole;
    }
  }

}
