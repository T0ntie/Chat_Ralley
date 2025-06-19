import 'package:aitrailsgo/engine/conversation.dart';
import 'package:aitrailsgo/engine/game_element.dart';
import 'package:aitrailsgo/engine/game_engine.dart';
import 'package:aitrailsgo/services/firebase_serice.dart';
import 'package:aitrailsgo/services/log_service.dart';

class StoryJournal with HasGameState {
  @override
  String id = "storyJournal";
  static final StoryJournal _instance = StoryJournal._internal();

  factory StoryJournal() => _instance;

  StoryJournal._internal() {
    registerSelf();
  }

  final List<(DateTime, String)> _entries = [];

  String toStory() => _entries.join("\n");

  void logPrompt(String npc, String prompt) {
    _entries.add((
      DateTime.now(),
      "## Die Beschreibung von **$npc**: \n\n $prompt",
    ));
  }

  static String _formatNpcMessage(String npc, String message, Medium medium) {
    final verb = (medium == Medium.radio) ? "funkt" : "sagt";
    return "$npc $verb: \"$message\"\n";
  }

  static String _formatUserMessage(String npc, String message, Medium medium) {
    final verb = (medium == Medium.radio) ? "funkt" : "sagt";
    return "Der Spieler $verb zu $npc: \"$message\"\n\n";
  }

  void logMessage(ChatMessage message, String npc)
  {
    String? entry;
    if (message.medium == Medium.trigger) {
      entry = "${message.filteredText}\n\n";
    } else if (message.chatRole == ChatRole.assistant) {
      entry = _formatNpcMessage(npc, message.filteredText, message.medium);
    } else if (message.chatRole == ChatRole.user) {
      entry = _formatUserMessage(npc, message.filteredText, message.medium);
    }
    if (entry != null) {
      _entries.add((DateTime.now(), entry));
      FirestoreService.logLiveJournalEntry(
        trailId: GameEngine().trailId!,
        type: "message",
        content: entry,
      );
    }
  }

/*
  void logMessage(Medium medium, ChatRole role, String npc, String message) {
    String? entry;

    if (medium == Medium.trigger) {
      entry = "- Es geschieht folgendes: $message\n\n";
    } else if (role == ChatRole.assistant) {
      entry = _formatNpcMessage(npc, message, medium);
    } else if (role == ChatRole.user) {
      entry = _formatUserMessage(npc, message, medium);
    }

    if (entry != null) {
      _entries.add((DateTime.now(), entry));
      FirestoreService.logLiveJournalEntry(
        trailId: GameEngine().trailId!,
        content: entry,
      );
    }
  }
*/

  void logAction(String action,{credits = true}) {
    if (credits) {
      _entries.add((DateTime.now(), action));
    }
    FirestoreService.logLiveJournalEntry(
      trailId: GameEngine().trailId!,
      type: "action",
      content: action,
    );
  }

  @override
  void loadGameState(Map<String, dynamic> json) {
    final journal = json['journal'];
    if (journal is! List) return;

    _entries.clear();

    for (final entry in journal) {
      final map = entry as Map<String, dynamic>?;
      final timestampStr = map?['timestamp'] as String?;
      final content = map?['content'] as String?;
      final timestamp = DateTime.tryParse(timestampStr ?? '');

      if (timestamp == null || content == null) {
        log.w(
            '⚠️ Invalid entries while loading jounal from game state: "$journal"');
        assert(false, '⚠️ Invalid entries while loading jounal from game state: "$journal"');
        continue;
      }

      _entries.add((timestamp, content));
    }
  }

  @override
  Map<String, dynamic> saveGameState() {
    final entriesJson = <Map<String, dynamic>>[];
    for (final (timestamp, content) in _entries) {
      entriesJson.add({
        'timestamp': timestamp.toIso8601String(),
        'content': content,
      });
    }
    return {'journal': entriesJson};
  }
}