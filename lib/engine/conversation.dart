import 'package:hello_world/engine/game_engine.dart';

import '../services/chat_service.dart';
import 'npc.dart';
import 'dart:convert';

class Conversation {
  final Npc npc; // Der NPC, mit dem der User chattet
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
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.user));
  }
  void addAssistantMessage(String message)
  {
    final ChatMessage chatMessage = ChatMessage(rawText: message, chatRole: ChatRole.assistant);
     _messages.add(chatMessage);
     if (chatMessage.signalString != null) {
       GameEngine.instance.registerSignal(chatMessage.signalString!);
     }
  }
  void addSystemMessage(String message)
  {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.system));
  }

/*
  void addMessage(ChatMessage message) {
    _messages.add(message);
  }
*/

  Future<String> processConversation() async
  {
    return await ChatService.processMessages(_toOpenAIMessages ());
  }

  List<Map<String, String>> _toOpenAIMessages() {
    return _messages.map((msg) => {
      'role': msg.getRoleString(),
      'content': msg.rawText,
    }).toList();
  }
}

enum ChatRole {user, assistant, system}

class ChatMessage {
static const userRole = "user";
static const assistantRole = "assistant";
static const systemRole = "system";

final String rawText; // die komplette Message, wie sie Chat-GPT bekommt (inklusive JSON Signale)
final String filteredText; //alle Singale rausgefiltert, so wie sie dem Benutzer angezeigt wird
//final Map<String, dynamic>? signal; // das extrahierte JSON Signal
final String? signalString;

final ChatRole chatRole;
ChatMessage({required this.rawText, required this.chatRole}): filteredText = _filterMessage(rawText),
      signalString = (chatRole == ChatRole.assistant) ? _extractSignalStatus(rawText) : null {
  if (chatRole == ChatRole.assistant ) {
    print("✅ Signal gefunden: $signalString");
  }
}

//entfernt alle signale aus der message
static String _filterMessage(String rawText) {
  final regex = RegExp(r'<json-signal>\s*([\s\S]*?)\s*<\/json-signal>', multiLine: true);
  return rawText.replaceAll(regex, '').trim();
}

  static String? _extractSignalStatus(String rawText) {
    final regex = RegExp(r'<json-signal>\s*([\s\S]*?)\s*<\/json-signal>', multiLine: true);
    final match = regex.firstMatch(rawText);

    if (match != null) {
      final jsonString = match.group(1);
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString!);
        return decoded['status']?.toString(); // falls 'status' existiert
      } catch (_) {
        return null;
      }
    }
    return null;
  }

/*
static Map<String, dynamic>? _extractSignal(String rawText) {
  final regex = RegExp(r'<json-signal>\s*([\s\S]*?)\s*<\/json-signal>', multiLine: true);
  final match = regex.firstMatch(rawText);
  if (match != null) {
    final jsonString = match.group(1);
    try {
      return jsonDecode(jsonString!);
    } catch (_) {
      return null;
    }
  }
  return null;
}
*/

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
