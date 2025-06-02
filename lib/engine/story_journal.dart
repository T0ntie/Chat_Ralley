import 'package:storytrail/engine/conversation.dart';
import 'package:storytrail/engine/game_element.dart';
import 'package:storytrail/services/log_service.dart';

class StoryJournal with HasGameState {
  @override
  String id = "storyJournal";
  static final StoryJournal _instance = StoryJournal._internal();

  factory StoryJournal() => _instance;

  StoryJournal._internal();

  final List<(DateTime, String)> _entries = [];

  String toStory() => _entries.join("\n");

  void logPrompt(String npc, String prompt) {
    _entries.add((
      DateTime.now(),
      "## Die Beschreibung von **$npc**: \n\n $prompt",
    ));
  }

  String _commVerb(Medium medium) {
    if (medium == Medium.radio) {
      return "sendet per Funk:";
    }
    return "sagt:";
  }

  void logMessage(Medium medium, ChatRole role, String npc, String message) {
    String entry;

    if (medium == Medium.trigger) {
      entry = "- Es geschieht folgendes: $message\n\n";
    }
    if (role == ChatRole.assistant) {
      entry = "- $npc ${_commVerb(medium)} $message\n\n";
    }
    if (role == ChatRole.user) {
      entry = "- der Spieler ${_commVerb(medium)} $message\n\n";
    } else {
      return;
    }
    _entries.add((DateTime.now(), entry));
  }

  void logAction(String action) {
    _entries.add((DateTime.now(), action));
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