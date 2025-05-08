import 'package:flutter/services.dart';
import 'package:hello_world/engine/story_line.dart';

class Prompt {
  Prompt._();

  static const String gamePromptFile = 'assets/story/prompts/game-prompt.txt';
  static const String compressPromptFile =
      'assets/story/prompts/summarize-prompt.txt';
  static const String promptAssetPath = 'assets/story/prompts/';

  late final String promptFile;

  final Map<String, String> promptSectionMap = {};
  final Map<String, Set<String>> tagToSections = {};

  static const String gamePlayTag = "gameplay";
  static const String summarizeTag = "summarize";

  static const String summarizeCommand = "[Fasse zusammen]";

  String getGameplayPrompt() {
    return getTaggedPrompt(gamePlayTag);
  }

  String getSummarizePrompt() {
    return getTaggedPrompt(summarizeTag);
  }

  String getTaggedPrompt(String tag) {
    final sections = tagToSections[tag];
    if (sections == null || sections.isEmpty) {
      throw StateError("❌ Kein Abschnitt mit Tag $tag im Prompt '$promptFile' gefunden.");
    }
    return getCustomPrompt(sections);
  }

  String getPromptSection(String section) {
    final content = promptSectionMap[section];
    if (content == null) {
      throw ArgumentError("Prompt-Abschnitt '$section' existiert nicht.");
    }
    return content;
  }

  String getCustomPrompt(Set selection) {
    final buffer = StringBuffer();

    for (final section in selection) {
      final content = promptSectionMap[section];
      if (content != null) {
        buffer.writeln(content);
        buffer.writeln(); // fügt eine Leerzeile zwischen Sektionen ein
      } else {
        throw StateError("❌ Abschnitt '$section' fehlt im Prompt '$promptFile'.");
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
      try {
        parsePromptSections(prompt, promptSectionMap, tagToSections);
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

  static void parsePromptSections(
      String prompt,
      Map<String, String> sectionMap,
      Map<String, Set<String>> tagMap,
      ) {
    sectionMap.clear();
    tagMap.clear();

    final RegExp sectionHeader = RegExp(r'^##\s(.+?)(?:\s\[(.+?)\])?$', multiLine: true);
    final matches = sectionHeader.allMatches(prompt).toList();

    for (int i = 0; i < matches.length; i++) {
      final currentMatch = matches[i];
      final String sectionTitle = currentMatch.group(1)!.trim();
      final String? tagsRaw = currentMatch.group(2);

      final sectionStart = currentMatch.end;
      final sectionEnd = (i + 1 < matches.length) ? matches[i + 1].start : prompt.length;
      final sectionContent = prompt.substring(sectionStart, sectionEnd).trim();

      sectionMap[sectionTitle] = sectionContent;

      if (tagsRaw != null) {
        final tags = tagsRaw.split(',').map((t) => t.trim().toLowerCase()).toSet();

        for (final tag in tags) {
          tagMap.putIfAbsent(tag, () => <String>{}).add(sectionTitle);
        }
      }
    }

//    print('🧩 Prompt-Parsing abgeschlossen.');
//    print('📚 Gefundene Abschnitte: ${sectionMap.length}');
//    print('🏷️  Tags erkannt: ${tagMap.keys.join(', ')}');

/*
    for (final tag in tagMap.entries) {
      print('🔖 Tag "${tag.key}": ${tag.value.length} Abschnitt(e)');
      for (final section in tag.value) {
        print('   → $section');
      }
    }
*/
  }
}
