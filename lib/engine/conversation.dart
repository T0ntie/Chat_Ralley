import 'package:storytrail/engine/game_element.dart';

import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/prompt.dart';
import 'package:storytrail/engine/story_journal.dart';

import 'package:storytrail/services/chat_service.dart';
import 'package:storytrail/engine/npc.dart';
import 'dart:convert';

import 'package:storytrail/services/log_service.dart';

class Conversation with HasGameState {
  final Npc npc; // Der NPC, mit dem der User chattet
  @override
  String id;
  final List<ChatMessage> _messages = []; // Liste von Nachrichten
  int userMessageCount = 0;

  int messagesToKeep = 10;

  Future<void> Function()? onConversationFinished;

  Conversation(this.npc) : id = "conversation_${npc.id}" {
    registerSelf();
    addPrompt(npc.prompt.getGameplayPrompt());
    log.d("💬 System prompt für NPC ${npc.name} hinzugefügt.");
  }

  Future<void> handleTriggerMessage() async {
    try {
      if (_messages.last.isTrigger) {
        String triggeredResponse = await processConversation();
        addAssistantMessage(triggeredResponse, Medium.chat);
      }
    }catch(e, stackTrace) {
     log.e('❌ Failed to process trigger conversation', error: e, stackTrace: stackTrace);
     rethrow;
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
            (msg) =>
        (!msg.fromSystem && !msg.isTrigger && msg.medium == medium),
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
    _jlog();
  }

  void addUserMessage(String message, Medium medium) {
    _messages.add(
      ChatMessage(rawText: message, chatRole: ChatRole.user, medium: medium),
    );
    _jlog();
    GameEngine().registerMessage(npc, ++userMessageCount);
  }

  void addAssistantMessage(String message, Medium medium) async {
    final ChatMessage chatMessage = ChatMessage(
      rawText: message,
      chatRole: ChatRole.assistant,
      medium: medium,
    );
    _messages.add(chatMessage);
    _jlog();

    if (chatMessage.signalJson.isNotEmpty) {
      await GameEngine().registerSignal(chatMessage.signalJson);
    }
  }

  void addPrompt(String message) {
    _messages.add(ChatMessage(
        rawText: message, chatRole: ChatRole.system, isInitialPrompt: true));
    _jlog();
  }

  void addSystemMessage(String message) {
    _messages.add(ChatMessage(rawText: message, chatRole: ChatRole.system));
    _jlog();
  }

  Future<void> _compressConversation() async {
    final keep = messagesToKeep;

    // 1) --- Listen vorbereiten -----------------------------------------------

    assert(
    _messages.any((m) => m.isInitialPrompt),
    'Fehlender Initial-Prompt – nicht vorhanden',
    );

    final initialPrompt = _messages.firstWhere(
          (m) => m.isInitialPrompt,
      orElse: () => ChatMessage(
        rawText: npc.prompt.getGameplayPrompt(),
        chatRole: ChatRole.system,
        isInitialPrompt: true,
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

    log.i("Summary durchgeführt: $summary");

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

  void _jlog() {
    if (_messages.isNotEmpty) {
      ChatMessage cm = _messages.last;
      if (cm.isInitialPrompt) {
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

  @override
  loadGameState(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List;
    //alle messages außer dem initial prompt entfernen
    _messages.removeWhere((m) => !m.isInitialPrompt);
    assert(_messages.any((m) => m.isInitialPrompt), 'Missing initial prompt after load!');

    if (!_messages.any((m) => m.isInitialPrompt)) {
      _messages.insert(
        0,
        ChatMessage(
          rawText: npc.prompt.getGameplayPrompt(),
          chatRole: ChatRole.system,
          isInitialPrompt: true,
        ),
      );
    }
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

  @override
  Map<String, dynamic> saveGameState() {
    final messagesJson = <Map<String, dynamic>>[];
    //System Prompt wird nicht gespeichert!
    final messagesToSave = _messages.where((m) => !m.isInitialPrompt).toList();

    for (final msg in messagesToSave) {
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
  final bool isInitialPrompt;

  ChatMessage({
    required this.rawText,
    required this.chatRole,
    this.medium = Medium.chat,
    this.isInitialPrompt = false,
    DateTime? timeStamp,
  })
      : timeStamp = timeStamp ?? DateTime.now(),
        filteredText = _filterMessage(rawText),
        signalJson =
        (chatRole == ChatRole.assistant) ? _extractSignal(rawText) : {} {
    if (chatRole == ChatRole.assistant && signalJson.isNotEmpty) {
      log.i("💬 Signal in Antwort von NPC gefunden: $signalJson");
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