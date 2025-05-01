import 'package:flutter/services.dart';
import 'package:hello_world/engine/story_line.dart';

class Prompt {
  Prompt._();

  static const String gamePromptFile = 'assets/story/prompts/game-prompt.txt';
  static const String compressPromptFile =
      'assets/story/prompts/compress-prompt.txt';
  static const String promptAssetPath = 'assets/story/prompts/';

  late final String promptFile;

  final Map<String, String> promptSectionMap = {};

  static final Set<String> validSections = {
    "Allgemeines",
    "Das Spiel",
    "Der Ort",
    "Deine Rolle",
    "Inspirationsquellen",
    "Deine Aufgabe",
    "Antwortstil",
    "Die wichtigsten Informationen",
    "Gesprächsverlauf",
    "Verhalten in besonderen Situationen",
    "Signale",
    "Zusammenfassungsregeln",
  };

  static Set<String> gamePlaySections = {
    "Allgemeines",
    "Das Spiel",
    "Der Ort",
    "Deine Rolle",
    "Inspirationsquellen",
    "Deine Aufgabe",
    "Antwortstil",
    "Die wichtigsten Informationen",
    "Gesprächsverlauf",
    "Verhalten in besonderen Situationen",
    "Signale",
  };

  static Set<String> compressSections = {
    "Deine Rolle",
    "Die wichtigsten Informationen",
    "Gesprächsverlauf",
    "Zusammenfassungsregeln",
  };

  String getGamplayPrompt() {
    return _getCustomPrompt(gamePlaySections);
  }

  String getCompressPrompt() {
    return _getCustomPrompt(compressSections);
  }

  String _getCustomPrompt(Set selection) {
    final buffer = StringBuffer();

    for (final section in selection) {
      final content = promptSectionMap[section];
      if (content != null) {
        buffer.writeln(content);
        buffer.writeln(); // fügt eine Leerzeile zwischen Sektionen ein
      } else {
        print(
          "⚠️ Warnung: Abschnitt '$section' ist im Prompt ${promptFile} nicht vorhanden.",
        );
      }
    }
    return buffer.toString().trim();
  }

  static Future<Prompt> createPrompt(String promptFile) async {
    final prompt = Prompt._();
    await prompt._loadPrompt(promptFile);
    return prompt;
  }

  Future<void> _loadPrompt(String promptFile) async {
    try {
      this.promptFile = promptFile;
      final String gamePrompt = await rootBundle.loadString(gamePromptFile);
      final String compressPrompt = await rootBundle.loadString(
        compressPromptFile,
      );
      final String npcPrompt = await rootBundle.loadString(
        promptAssetPath + promptFile,
      );
      String prompt = StoryLine.localizeString(
        gamePrompt + npcPrompt + compressPrompt,
      );
      //print("Start parsing prompt: $promptFile");
      try {
        promptSectionMap.addAll(parsePromptSections(prompt));
      } catch (e) {
        print("❌ Feher beim Parsen von '$promptFile': $e");
        rethrow;
      }
    } catch (e, stack) {
      print(
        '❌ Failed to load prompt files $gamePromptFile or $promptFile:\n$e\n$stack',
      );
      rethrow;
    }
  }

  static Map<String, String> parsePromptSections(String prompt) {
    final Map<String, String> sections = {};
    final RegExp sectionHeader = RegExp(r'^## (.+)', multiLine: true);
    final matches = sectionHeader.allMatches(prompt).toList();
    final List<String> errorList = [];

    for (int i = 0; i < matches.length; i++) {
      final currentMatch = matches[i];
      final sectionTitle = currentMatch.group(1)!.trim();

      final sectionStart = currentMatch.start;
      final sectionEnd =
          (i + 1 < matches.length) ? matches[i + 1].start : prompt.length;

      if (!validSections.contains(sectionTitle)) {
        errorList.add("$sectionTitle");
      }

      final sectionContent = prompt.substring(sectionStart, sectionEnd).trim();
      sections[sectionTitle] = sectionContent;
    }
    if (errorList.isNotEmpty) {
      throw FormatException(
        "Unbekannte Abschnittstitel im Prompt: ${errorList.join(', ')}",
      );
    }
    return sections;
  }
}
