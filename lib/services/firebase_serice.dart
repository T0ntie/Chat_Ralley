import 'package:http/http.dart' as http;
import 'dart:convert';

class JsonLoader {
  static Future<Map<String, dynamic>> loadJsonFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('Fehler beim Laden [$url]: HTTP ${response.statusCode}');
      }
    } catch (e, stack) {
      print('❌ Fehler beim Laden von JSON aus $url:\n$e\n$stack');
      rethrow;
    }
  }
}
