import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hello_world/engine/story_line.dart';

class Prompt {
  Prompt._();

  static const String gamePromptFile = 'assets/story/prompts/game-prompt.txt';
  static const String promptSectionsFile = 'assets/story/prompts.json';
  static const String compressPromptFile =
      'assets/story/prompts/compress-prompt.txt';
  static const String promptAssetPath = 'assets/story/prompts/';

  late final String promptFile;

  final Map<String, String> promptSectionMap = {};

  static final Set<String> validSections = <String>{};
  static Set<String> gamePlaySections = <String>{};
  static Set<String> compressSections = <String>{};

  static const String compressCommand = "[Fasse zusammen]";

  String getGamplayPrompt() {
    return _getCustomPrompt(gamePlaySections);
  }

  String getCompressPrompt() {
    return _getCustomPrompt(compressSections);
  }

  String getPromptSection(String section) {
    final content = promptSectionMap[section];
    if (content == null) {
      throw ArgumentError("Prompt-Abschnitt '$section' existiert nicht.");
    }
    return content;
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
    if (validSections.isEmpty){
      await _loadPromptsections();
    }
    await prompt._loadPrompt(promptFile);
    return prompt;
  }

  static Future<void> _loadPromptsections() async {
    try {
      String jsonString = await rootBundle.loadString(promptSectionsFile);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      validSections.addAll(Set<String>.from(json['validSections']));
      gamePlaySections.addAll(Set<String>.from(json['gamePlaySections']));
      compressSections.addAll(Set<String>.from(json['compressSections']));
    } catch (e) {
      print("❌ Feher beim Parsen der Promptsections '$promptSectionsFile': $e");
      rethrow;
    }
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
