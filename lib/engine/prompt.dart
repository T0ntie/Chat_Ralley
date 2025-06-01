import 'package:storytrail/services/firebase_serice.dart';
import 'package:storytrail/services/log_service.dart';

class Prompt {
  Prompt._();

  static const String promptUriPath = 'tibia/prompts/';
  static const String gamePromptUri = '${promptUriPath}game-prompt.txt';
  static const String compressPromptUri = '${promptUriPath}summarize-prompt.txt';

  late final String promptFile;

  final Map<String, String> promptSectionMap = {};
  final Map<String, Set<String>> tagToSections = {};

  static const String gamePlayTag = "gameplay";
  static const String summarizeTag = "summarize";
  static const String creditsTag = "credits";

  static const String summarizeCommand = "[Fasse zusammen]";

  String getGameplayPrompt() {
    return getTaggedPrompt(gamePlayTag);
  }

  String getSummarizePrompt() {
    return getTaggedPrompt(summarizeTag);
  }

  String getCreditsPrompt() {
    return getTaggedPrompt(creditsTag);
  }

  String getTaggedPrompt(String tag) {
    final sections = tagToSections[tag];
    if (sections == null || sections.isEmpty) {
      log.e('❌ no section found with tag "$tag" in prompt "$promptFile" found.');
      throw StateError('❌ no section found with tag "$tag" in prompt "$promptFile" found.');
    }
    return getCustomPrompt(sections);
  }

  String getPromptSection(String section) {
    final content = promptSectionMap[section];
    if (content == null) {
      log.e('❌ there is no section called "$section".');
      throw ArgumentError('❌ there is no section called "$section".');
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
        log.e('❌ section "$section" missing in prompt "$promptFile".');
        throw StateError('❌ section "$section" missing in prompt "$promptFile".');
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
    this.promptFile = promptFile;
    final String gamePrompt;
    try {
      gamePrompt = await FirebaseHosting.loadStringFromUrl(
          gamePromptUri);
    } catch (e, stackTrace) {
      log.e('❌ failed to load prompt file "$gamePromptUri".', error: e,
          stackTrace: stackTrace);
      rethrow;
    }

    final String compressPrompt;
    try {
      compressPrompt = await FirebaseHosting.loadStringFromUrl(
          compressPromptUri);
    } catch (e, stackTrace) {
      log.e('❌ failed to load prompt file "$compressPromptUri".', error: e,
          stackTrace: stackTrace);
      rethrow;
    }

    final String npcPrompt;
    try {
      npcPrompt =
      await FirebaseHosting.loadStringFromUrl('$promptUriPath$promptFile');
    } catch (e, stackTrace) {
      log.e('❌ failed to load prompt file "$promptUriPath$promptFile".',
          error: e, stackTrace: stackTrace);
      rethrow;
    }

    String prompt = gamePrompt + npcPrompt + compressPrompt;
    try {
      parsePromptSections(prompt, promptSectionMap, tagToSections);
    } catch (e, stackTrace) {
      log.e('❌ failed to parse prompt sections in "$promptFile".', error: e,
          stackTrace: stackTrace);
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
