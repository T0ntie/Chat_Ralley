import 'dart:ui';

import 'package:hello_world/engine/conversation.dart';
import 'package:hello_world/engine/game_engine.dart';

class StoryJournal {
  static final StoryJournal _instance = StoryJournal._internal();

  factory StoryJournal() => _instance;

  StoryJournal._internal();

  final List<JournalEntry> _entries = [];

  String toStory()
  {
    final story= _entries.map((entry) => entry.toStory()).join("\n");
    print ("--------${story}");
    return story;
  }

  void logPrompt(String npc, String prompt)
  {
    JournalEntry entry = new PromptJournalEntry(npc: npc, prompt: prompt);
  }

  void logMessage(Medium medium, ChatRole role, String npc, String message)
  {
    JournalEntry entry = new DialogJournalEntry(medium: medium, role: role, npc: npc, message: message);
    print (" 🐱‍👤 Journal Entry : " + _shorten(entry.toStory()));
    _entries.add(entry);
  }

  void logAction(String action) {
    JournalEntry entry = new ActionJournalEntry(action: action);
    print (" 🐱‍👤 Journal Entry : " + _shorten(entry.toStory()));
    _entries.add(entry);
  }

  String _shorten (String message) {
    return  message.length > 100 ? message.substring(0, 100) + "..." : message;
  }
}

enum JournalEntryType { dialogue, action }

// Eintrag im Journal
abstract class JournalEntry {
  final DateTime timestamp;

  JournalEntry({DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  String toStory();
}

class PromptJournalEntry extends JournalEntry {
  final String prompt;
  final String npc;
  PromptJournalEntry({required this.npc, required this.prompt, DateTime? timestamp}): super(timestamp: timestamp);

  String toStory()
  {
    return ("## Die Beschreibung von **${npc}**: \n\n ${prompt}");
  }
}

class ActionJournalEntry extends JournalEntry {
  final String action;
  ActionJournalEntry ({required this.action, DateTime? timestamp}): super(timestamp: timestamp);

  String toStory() {
    return action;
  }
}

class DialogJournalEntry extends JournalEntry {
  final ChatRole role;
  final String npc;
  final String message;
  final Medium medium;

  DialogJournalEntry({
    required this.role,
    required this.npc,
    required this.message,
    required this.medium,
    DateTime? timestamp,
  }) : super(timestamp: timestamp);

  String _commVerb()
  {
    if (message == Medium.chat){
      return "sendet per Funk:";
    }
    return "sagt:";
  }

  @override
  String toStory() {
    if (medium == Medium.trigger) {
      return "- Es geschieht folgendes: ${message}\n\n";
    }
    if (role == ChatRole.assistant) {
      return "- ${npc} " + _commVerb() + " ${message}\n\n";
    }
    if (role == ChatRole.user) {
      return "- der Spieler " + _commVerb() + " ${message}\n\n";
    }

    print("folgende message wird ignoriert: $message ");
    return "";
  }
}