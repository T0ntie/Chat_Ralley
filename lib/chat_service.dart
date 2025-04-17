import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ChatService {
  static const _url = 'https://api.openai.com/v1/chat/completions';

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
          'model': 'gpt-4.1',
          'messages': messages,
          'n': 1,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['choices'][0]['message']['content'];
      } else {
        throw Exception('Fehler: ${response.statusCode} - ${response.body}');
      }
    }catch (e, stack) {
      print('❌ Fehler bei der Kommunikation mit Chat GPT :\n$e\n$stack');
      rethrow;
    }
  }
}

