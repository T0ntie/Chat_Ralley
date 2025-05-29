import 'package:flutter/services.dart';
import 'package:storytrail/services/chat_service.dart';

class GptUtilities {
  static const String utilityPromptFile =
      "assets/story/prompts/utility-prompt.txt";

  static const String creditsPromptFile =
      "assets/story/prompts/credits-prompt.txt";

  static String? utilityPrompt;
  static String? creditsPrompt;

  static Future<void> init() async {
    try {
      utilityPrompt = await rootBundle.loadString(utilityPromptFile);
      creditsPrompt = await rootBundle.loadString(creditsPromptFile);
    } catch (e, stack) {
      print('❌ Failed to load prompt files\n$e\n$stack');
      rethrow;
    }
  }

  static Future<String> buildCreditsStory(String journal) async{
    if (creditsPrompt == null) {
      throw Exception(
        "❌ GPT Utilities not initialized, no creditPrompt available",
      );
    }
    final messages = [
      {"role": "system", "content": creditsPrompt!},
      {
        "role": "system", "content": journal,
      },
      {
        "role": "user", "content": "Bitte beschreibe den Spielverlauf",
      }
    ];
    final response = await ChatService.processMessages(messages);
    return response.trim();

  }

  static Future<String> buildGrammaticalSentence({
    required String subject,
    required String predicate,
    required String akkusativeObject,
    required String dativeObject,
  }) async {
    if (utilityPrompt == null) {
      throw Exception(
        "❌ GPT Utilities not initialized, no utilityPrompt available",
      );
    }

    final pattern = "{{Subjekt}} {{Prädikat}} {{Akkusativobjekt}} {{Dativobjekt}}.";
    final content = "-Subjekt: $subject\n-Prädikat: $predicate\n-Akkusativobjekt: $akkusativeObject\n-Dativobjekt: $dativeObject";

    final messages = [
      {"role": "system", "content": utilityPrompt!},
      {
        "role": "user",  "content": "$pattern\n$content",
      },
    ];
    final response = await ChatService.processMessages(messages);
    return response.trim();
  }
}