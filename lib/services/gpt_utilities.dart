import 'package:flutter/services.dart';
import 'package:hello_world/services/chat_service.dart';

class GptUtilities {
  static const String utilityPromptFile =
      "assets/story/prompts/utility-prompt.txt";

  static String? utilityPrompt;

  static Future<void> init() async {
    try {
      utilityPrompt = await rootBundle.loadString(utilityPromptFile);
    } catch (e, stack) {
      print('❌ Failed to load prompt files $utilityPrompt\n$e\n$stack');
      rethrow;
    }
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
    final content = "-Subjekt: ${subject}\n-Prädikat: ${predicate}\n-Akkusativobjekt: ${akkusativeObject}\n-Dativobjekt: ${dativeObject}";

    final messages = [
      {"role": "system", "content": utilityPrompt!},
      {
        "role": "user",  "content": "${pattern}\n${content}",
      },
    ];
    final response = await ChatService.processMessages(messages);
    return response.trim();
  }
}
