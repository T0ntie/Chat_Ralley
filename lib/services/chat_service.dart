import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aitrailsgo/services/log_service.dart';
import 'package:tiktoken/tiktoken.dart';

class ChatService {
  //static const _url = 'https://api.openai.com/v1/chat/completions';
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

  static const _firebaseFunctionUrl = 'https://callgpt-erqoo6fo7q-uc.a.run.app';

  static Future<String> processMessages(
    List<Map<String, String>> messages,
  ) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(_firebaseFunctionUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'messages': messages, 'model': _model}),
      );
    } catch (e, stackTrace) {
      log.e(
        '❌ Failed to post to firebase function "$_firebaseFunctionUrl".',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['reply'];
      } catch (e, stackTrace) {
        log.e(
          '❌ Failed to decode response from firebase function "$_firebaseFunctionUrl".',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    } else {
      log.e(
        '❌ Recived errorcode from firebase function "$_firebaseFunctionUrl" : ${response.statusCode} - ${response.body}',
        error: response.body,
      );
      throw Exception('Errorcode: ${response.statusCode} - ${response.body}');
    }
  }

  //wurde ins backend verlagert

  /*
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
*/
  /*
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
*/
}