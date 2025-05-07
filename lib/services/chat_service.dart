import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tiktoken/tiktoken.dart';


class ChatService {
  static const _url = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4.1';
  static const _encodingModel = 'gpt-4';
  static const tokenLimit = 1000000;
  static const tokenThreshold = 7000;

  static bool needsContextCompression(List<Map<String, String>> messages) {
    return tokenThreshold < countTokens(messages);
  }

  static int countTokens(List<Map<String, String>> messages) {
    final encoding = encodingForModel(_encodingModel);
    int tokenCount = 0;

    for (var message in messages) {
      tokenCount += 4; // Basis-Tokenanzahl laut OpenAI für jede Nachricht
      message.forEach((key, value) {
        tokenCount += encoding.encode(value).length;
      });
    }

    tokenCount += 2; // Für systemmessage priming am Anfang
    return tokenCount;
  }

  static Future<String> processMessages(List<Map<String, String>> messages) async
  {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        print('❌ OPENAI-API-Key ist nicht gesetzt!');
        throw Exception('❌ OPENAI-API-Key ist nicht gesetzt.');
      }

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'n': 1,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        //final usedModel = decoded['model'];
        //print('📦 Verwendetes Modell laut API-Antwort: $usedModel');
        return decoded['choices'][0]['message']['content'];
      } else {
        throw Exception('Fehler: ${response.statusCode} - ${response.body}');
      }
    }catch (e, stack) {
      print('❌ Fehler bei der Kommunikation mit Chat GPT :\n$e\n$stack');
      rethrow;
    }
  }

  static Future<String> generateItemMessage(String npcName, String itemName) async {
    final messages = [
      {
        "role": "system",
        "content":
        "Du bist ein Sprachassistent in einem deutschsprachigen Abenteuerspiel. Deine Aufgabe ist es, kurze, grammatikalisch korrekte Spielnachrichten zu erzeugen. Halte die Sätze einfach, direkt und spielnah. Verwende gelegentlich andere Verben oder Satzstrukturen, aber keine Erklärungen oder Zusatztexte.",
      },
      {
        "role": "user",
        "content": '''
Formuliere folgenden Satz grammatikalisch korrekt auf Deutsch und gib **nur eine** Variante zurück:

Satz: "Du zeigst [npcName] [itemName]."
npcName: $npcName
itemName: $itemName
''',
      },
    ];

    final response = await ChatService.processMessages(messages);
    return response.trim();
  }

}

