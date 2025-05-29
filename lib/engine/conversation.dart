import 'package:storytrail/engine/game_element.dart';

import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/prompt.dart';
import 'package:storytrail/engine/story_journal.dart';

import 'package:storytrail/services/chat_service.dart';
import 'package:storytrail/engine/npc.dart';
import 'dart:convert';

class Conversation with HasGameState {
  final Npc npc; // Der NPC, mit dem der User chattet
  String id;
  final List<ChatMessage> _messages = []; // Liste von Nachrichten
  int userMessageCount = 0;

  int messagesToKeep = 10;

  Future<void> Function()? onConversationFinished;

  Conversation(this.npc) : id = "conversation_${npc.id}" {
    addSystemMessage(npc.prompt.getGameplayPrompt());
  }

  Future<void> handleTriggerMessage() async {
    if (_messages.last.isTrigger) {
      String triggeredResponse = await processConversation();
      //print('triggered Response is $triggeredResponse');
      addAssistantMessage(triggeredResponse, Medium.chat);
    }
  }

  Future<void> finishConversation() async {
    await onConversationFinished?.call();
  }

  List<ChatMessage> getMessages() {
    return List.unmodifiable(_messages); // Unmodifiable List zurückgeben
  }

  List<ChatMessage> getVisibleMessages(Medium medium) {
    return List.unmodifiable(
      _messages.where(
        (msg) => (!msg.fromSystem && !msg.isTrigger && msg.medium == medium),
      ),
    );
  }

  void addTriggerMessage(String message) {
    _messages.add(
      ChatMessage(
        rawText: message,
        chatRole: ChatRole.user,
        medium: Medium.trigger,
      ),
    );
    _log();
  }

  void addUserMessage(String message, Medium medium) {
    _messages.add(
      ChatMessage(rawText: message, chatRole: ChatRole.user, medium: medium),
    );
    _log();
    GameEngine().registerMessage(npc, ++userMessageCount);
  }

  void addAssistantMessage(String message, Medium medium) async {
    final ChatMessage chatMessage = ChatMessage(
      rawText: message,
      chatRole: ChatRole.assistant,
      medium: medium,
    );
    _messages.add(chatMessage);
    _log();

    if (chatMessage.signalJson.isNotEmpty) {
      await GameEngine().registerSignal(chatMessage.signalJson);
    }
  }

  void addSystemMessage(String message) {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.system));
    _log();
  }

  Future<void> _compressConversation() async {
    final keep = messagesToKeep;

    // 1) --- Listen vorbereiten -----------------------------------------------

    final initialPrompt = _messages.firstWhere(
      (m) => m.fromSystem,
      orElse:
          () => ChatMessage(
            rawText: npc.prompt.getGameplayPrompt(),
            chatRole: ChatRole.system,
          ),
    );

    final List<ChatMessage> laterSystem = [];
    final List<ChatMessage> userAssist = [];

    // Ab Index 1 durchsuchen, damit initialPrompt nicht doppelt landet
    for (var i = 1; i < _messages.length; i++) {
      final m = _messages[i];
      (m.fromSystem ? laterSystem : userAssist).add(m);
    }

    if (userAssist.length <= keep && laterSystem.isEmpty) {
      return; // nichts zu tun
    }

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
        .map((msg) => {'role': msg.chatRole.name, 'content': msg.rawText})
        .toList();
  }

  void _log() {
    if (_messages.isNotEmpty) {
      ChatMessage cm = _messages.last;
      if (_messages.length == 1 && cm.chatRole == ChatRole.system) {
        //print("Prompt-message detected:");
        StoryJournal().logPrompt(npc.name, npc.prompt.getCreditsPrompt());
      }

      StoryJournal().logMessage(
        cm.medium,
        cm.chatRole,
        npc.name,
        cm.filteredText,
      );
    }
  }

  loadGameState(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List;
    for (final msgJson in messagesJson) {
      final msg = ChatMessage(
        rawText: msgJson['content'],
        chatRole: ChatRole.values.firstWhere((e) => e.name == msgJson['role']),
        medium: Medium.values.firstWhere((e) => e.name == msgJson['medium']),
        timeStamp: DateTime.parse(msgJson['timeStamp']),
      );
      _messages.add(msg);
    }
  }

  Map<String, dynamic> saveGameState() {
    final messagesJson = <Map<String, dynamic>>[];
    for (final msg in _messages) {
      messagesJson.add({
        'role': msg.chatRole.name,
        'content': msg.rawText,
        'timeStamp': msg.timeStamp.toIso8601String(),
        'medium': msg.medium.name,
      });
    }
    return {
      'npcId': npc.id,
      'userMessageCount': userMessageCount,
      'messages': messagesJson,
    };
  }
}

enum ChatRole { user, assistant, system }

enum Medium { chat, radio, trigger }

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
  final DateTime timeStamp;

  ChatMessage({
    required this.rawText,
    required this.chatRole,
    this.medium = Medium.chat,
    DateTime? timeStamp,
  }) : timeStamp = timeStamp ?? DateTime.now(), filteredText = _filterMessage(rawText),
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
}
