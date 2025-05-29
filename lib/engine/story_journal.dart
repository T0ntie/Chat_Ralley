import 'package:storytrail/engine/conversation.dart';
import 'package:storytrail/engine/game_element.dart';

class StoryJournal with HasGameState {
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

  void loadGameState(Map<String, dynamic> json) {}

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
