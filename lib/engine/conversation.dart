import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/prompt.dart';

import '../services/chat_service.dart';
import 'npc.dart';
import 'dart:convert';

class Conversation {
  final Npc npc; // Der NPC, mit dem der User chattet
  final List<ChatMessage> _messages = []; // Liste von Nachrichten
  int userMessageCount = 0;

  int messagesToKeep = 10;

  void Function()? onConversationFinished;

  Conversation(this.npc) {
    addSystemMessage(npc.prompt.getGameplayPrompt());
  }

  Future<void> handleTriggerMessage() async {
    if (_messages.last.isTrigger) {
      String triggeredResponse = await processConversation();
      //print('triggered Response is $triggeredResponse');
      addAssistantMessage(triggeredResponse, Medium.chat);
    }
  }

  void finishConversation() {
    print("Schließe das chat fenster: conversation finished");
    onConversationFinished?.call();
  }

  List<ChatMessage> getMessages() {
    return List.unmodifiable(_messages); // Unmodifiable List zurückgeben
  }

  List<ChatMessage> getVisibleMessages(Medium medium) {
    return List.unmodifiable(
      _messages.where((msg) => (!msg.fromSystem && !msg.isTrigger && msg.medium == medium)),
    );
  }

  void addTriggerMessage(String message) {
    _messages.add(
      ChatMessage(rawText: message, chatRole: ChatRole.user, medium: Medium.trigger),
    );
  }

  void addUserMessage(String message, Medium medium) {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.user, medium: medium));
    GameEngine().registerMessage(npc, ++userMessageCount);
  }

  void addAssistantMessage(String message, Medium medium) {
    final ChatMessage chatMessage = ChatMessage(
      rawText: message,
      chatRole: ChatRole.assistant,
      medium: medium,
    );
    _messages.add(chatMessage);
    if (chatMessage.signalJson.isNotEmpty) {
      GameEngine().registerSignal(chatMessage.signalJson);
    }
  }

  void addSystemMessage(String message) {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.system));
  }

  Future<void> _compressConversation() async {
    final keep = messagesToKeep;

    // 1) --- Listen vorbereiten -----------------------------------------------

    final initialPrompt = _messages.firstWhere(
          (m) => m.fromSystem,
      orElse: () =>
          ChatMessage(
              rawText: npc.prompt.getGameplayPrompt(),
              chatRole: ChatRole.system),
    );

    final List<ChatMessage> laterSystem = [];
    final List<ChatMessage> userAssist = [];

    // Ab Index 1 durchsuchen, damit initialPrompt nicht doppelt landet
    for (var i = 1; i < _messages.length; i++) {
      final m = _messages[i];
      (m.fromSystem ? laterSystem : userAssist).add(m);
    }

    if (userAssist.length <= keep && laterSystem.isEmpty)
      return; // nichts zu tun

    // 2) --- bestimmen, was behalten / zusammengefasst wird -------------------
    final userAssistToKeep = userAssist.sublist(
      userAssist.length - keep.clamp(0, userAssist.length),
    );

    final toSummarize = [
      ...laterSystem,
      ...userAssist.sublist(0, userAssist.length - userAssistToKeep.length),
    ];

    // 3) --- GPT-Aufruf --------------------------------------------------------
    final promptForGPT = [
      ChatMessage(
        rawText: npc.prompt.getSummarizePrompt(),
        chatRole: ChatRole.system,
      ),
      ...toSummarize,
      ChatMessage(
        rawText: Prompt.summarizeCommand, //  "[Fasse zusammen]"
        chatRole: ChatRole.user,
      ),
    ];

    final summary = await _processConversation(promptForGPT);

    print("Summary durchgeführt: $summary");

    // 4) --- Neue Nachrichtenliste zusammenbauen ------------------------------
    _messages
      ..clear()
      ..addAll([
        initialPrompt,
        ChatMessage(rawText: summary, chatRole: ChatRole.system),
        ...userAssistToKeep,
      ]);
  }

  bool _isSummarizing = false;

  Future<String> _processConversation(List<ChatMessage> messages) async {
    if (!_isSummarizing &&
        ChatService.needsContextCompression(_toOpenAIMessages(messages))) {
      _isSummarizing = true;
      try {
        await _compressConversation();
      } finally {
        _isSummarizing = false;
      }
    }
    return ChatService.processMessages(_toOpenAIMessages(messages));
  }

  Future<String> processConversation() => _processConversation(_messages);

  List<Map<String, String>> _toOpenAIMessages(List<ChatMessage> messages) {
    return messages
        .map((msg) => {'role': msg.getRoleString(), 'content': msg.rawText})
        .toList();
  }
}

enum ChatRole { user, assistant, system }
enum Medium {chat, radio, trigger}

class ChatMessage {
  static const userRole = "user";
  static const assistantRole = "assistant";
  static const systemRole = "system";

  final String
  rawText; // die komplette Message, wie sie Chat-GPT bekommt (inklusive JSON Signale)
  final String
  filteredText; //alle Singale rausgefiltert, so wie sie dem Benutzer angezeigt wird
  late final Map<String, dynamic> signalJson;

  bool get isTrigger => medium == Medium.trigger;
  final ChatRole chatRole;
  final Medium medium;

  ChatMessage({
    required this.rawText,
    required this.chatRole,
    //this.isTrigger = false,
    this.medium = Medium.chat,
  }) : filteredText = _filterMessage(rawText),
       signalJson =
           (chatRole == ChatRole.assistant) ? _extractSignal(rawText) : {} {
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

  static Map<String, dynamic> _extractSignal(String rawText) {
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
