import 'package:hello_world/engine/game_engine.dart';

import '../services/chat_service.dart';
import 'npc.dart';
import 'dart:convert';

class Conversation {

  final Npc npc; // Der NPC, mit dem der User chattet
  final List<ChatMessage> _messages = []; // Liste von Nachrichten
  int userMessageCount = 0;

  void Function()? onConversationFinished;

  Conversation(this.npc) {
    addSystemMessage(npc.prompt);
  }

  Future<void> handleTriggerMessage() async {
    if (_messages.last.isTrigger) {
      String triggeredResponse = await processConversation();
      //print('triggered Response is $triggeredResponse');
      addAssistantMessage(triggeredResponse);
    }
  }

  void finishConversation()
  {
    print("Schließe das chat fenster: conversation finished");
    onConversationFinished?.call();
  }

  List<ChatMessage> getMessages() {
    return List.unmodifiable(_messages); // Unmodifiable List zurückgeben
  }

  List<ChatMessage> getVisibleMessages() {
    return List.unmodifiable(
      _messages.where((msg) => (!msg.fromSystem && !msg.isTrigger)),
    );
  }

  void addTriggerMessage(String message) {
    _messages.add(
      ChatMessage(rawText: message, chatRole: ChatRole.user, isTrigger: true),
    );
  }

  void addUserMessage(String message) {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.user));
    GameEngine().registerMessage(npc, ++userMessageCount);
  }

  void addAssistantMessage(String message) {
    final ChatMessage chatMessage = ChatMessage(
      rawText: message,
      chatRole: ChatRole.assistant,
    );
    _messages.add(chatMessage);
    if (chatMessage.signalJson.isNotEmpty) {
      GameEngine().registerSignal(chatMessage.signalJson);
    }
  }

  void addSystemMessage(String message) {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.system));
  }

  Future<String> processConversation() async {
    final response = await ChatService.processMessages(_toOpenAIMessages());
    final count = ChatService.countTokens(_toOpenAIMessages());
    print("Currently $count tokens used");
    return response;
  }

  List<Map<String, String>> _toOpenAIMessages() {
    return _messages
        .map((msg) => {'role': msg.getRoleString(), 'content': msg.rawText})
        .toList();
  }
}

enum ChatRole { user, assistant, system }

class ChatMessage {
  static const userRole = "user";
  static const assistantRole = "assistant";
  static const systemRole = "system";

  final String
  rawText; // die komplette Message, wie sie Chat-GPT bekommt (inklusive JSON Signale)
  final String
  filteredText; //alle Singale rausgefiltert, so wie sie dem Benutzer angezeigt wird
  late final Map<String, dynamic> signalJson;
  bool isTrigger;

  final ChatRole chatRole;

  ChatMessage({
    required this.rawText,
    required this.chatRole,
    this.isTrigger = false,
  }) : filteredText = _filterMessage(rawText),
       signalJson =
           (chatRole == ChatRole.assistant)
               ? _extractSignal(rawText)
               : {} {
    if (chatRole == ChatRole.assistant && signalJson.isNotEmpty) {
      print("✅ Signal gefunden: $signalJson");
    }
  }

  //entfernt alle signale aus der message
  static String _filterMessage(String rawText) {
    final regex = RegExp(
      r'<npc-signal>\s*([\s\S]*?)\s*<\/npc-signal>',
      multiLine: true,
    );
    return rawText.replaceAll(regex, '').trim();
  }

  static Map<String, dynamic> _extractSignal(String rawText){
    final regex = RegExp(
      r'<npc-signal>\s*([\s\S]*?)\s*<\/npc-signal>',
      multiLine: true,
    );
    final match = regex.firstMatch(rawText);
    if (match != null) {
      final jsonString = match.group(1);
      try {
        return jsonDecode(jsonString!);
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  // Getter für "fromUser"
  bool get fromUser => chatRole == ChatRole.user;
  bool get fromAssistant => chatRole == ChatRole.assistant;
  bool get fromSystem => chatRole == ChatRole.system;

  String getRoleString() {
    switch (chatRole) {
      case ChatRole.user:
        return userRole;
      case ChatRole.assistant:
        return assistantRole;
      case ChatRole.system:
        return systemRole;
    }
  }
}
