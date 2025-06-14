
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Für JSON-Decoding und UTF-8
// ignore_for_file: avoid_print
// Basis-URL deines Firebase Hostings, wie in deinem FirebaseHosting Klasse
const String firebaseHostingBaseUrl = 'https://aitrailsgo.web.app/';

// Liste der Dateipfade zu JSON-Dateien, die du auf Firebase Hosting erwartest.
// Wichtig: Diese Pfade sind relativ zum ROOT deines gehosteten Inhalts,
// d.h. relativ zu dem Ordner, der in firebase.json als 'public' definiert ist.
// Füge hier NICHT '/public/' oder die Basis-URL hinzu.
const List<String> jsonFilePaths = [
  'tibia/positions.json', // Beispiel-Pfad, basierend auf deiner früheren Frage
  'tibia/storyline.json',       // Annahme: Deine Haupt-Storyline-Datei liegt auch dort
  // Füge hier weitere Pfade zu deinen JSON-Dateien hinzu, z.B.:
  // 'data/items.json',
  // 'config/settings.json',
];

// Liste der Dateipfade zu Textdateien (.txt, etc.), die du auf Firebase Hosting erwartest.
// Wiederum: Diese Pfade sind relativ zum ROOT deines gehosteten Inhalts.
const List<String> textFilePaths = [
  // Füge hier Pfade zu deinen Textdateien hinzu, z.B.:
  'tibia/prompts/beissbert-prompt.txt',
  'tibia/prompts/bozzi-prompt.txt',
  'tibia/prompts/credits-prompt.txt',
  'tibia/prompts/game-prompt.txt',
  'tibia/prompts/knatterbach-prompt.txt',
  'tibia/prompts/knöchelbein-prompt.txt',
  'tibia/prompts/kroll-prompt.txt',
  'tibia/prompts/summarize-prompt.txt',
  'tibia/prompts/tschulli-prompt.txt',
  'tibia/prompts/utility-prompt.txt',
  // 'logs/changelog.md', // Markdown ist auch nur Text
];

void main() {
  // Testgruppe für JSON-Dateien
  group('Firebase Hosting JSON Files', () {
    for (final filePath in jsonFilePaths) {
      test('File "$filePath" should be accessible, UTF-8 encoded, and valid JSON', () async {
        final fullUrl = Uri.parse('$firebaseHostingBaseUrl$filePath');

        try {
          final response = await http.get(fullUrl);

          // 1. Prüfe den Statuscode
          expect(
            response.statusCode,
            200,
            reason: 'Expected status code 200 for $fullUrl. Received ${response.statusCode}. '
                'Body: ${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}', // Zeige ggf. einen Teil des Fehler-Bodys
          );

          // 2. Prüfe, ob der Content-Type Header auf JSON hindeutet (optional, da wir bodyBytes verwenden)
          // Firebase setzt oft den richtigen Content-Type basierend auf der Dateiendung.
          // Dieser Check ist hilfreich, um sicherzustellen, dass der Server den Dateityp erkennt.
          final contentType = response.headers['content-type'] ?? '';
          expect(
              contentType,
              startsWith('application/json'),
              reason: 'Expected Content-Type starting with "application/json" for $fullUrl. Received "$contentType".'
          );


          // 3. Prüfe die UTF-8 Dekodierung und die JSON Gültigkeit
          try {
            // Verwende bodyBytes und utf8.decode, genau wie in deiner FirebaseHosting Klasse
            final String decodedBody = utf8.decode(response.bodyBytes);

            // Versuche, den dekodierten String als JSON zu parsen
            jsonDecode(decodedBody);

            print('✅ Success: "$filePath" ($fullUrl) is accessible, UTF-8, and valid JSON.');

          } on FormatException catch (e) {
            // Dieser Fehler tritt auf, wenn jsonDecode fehlschlägt
            fail('❌ Failed to parse JSON from "$filePath" ($fullUrl). Content is not valid JSON or not properly UTF-8 encoded: $e');
          } catch (e) {
            // Andere Fehler während der Dekodierung/Parsing
            fail('❌ An unexpected error occurred while processing "$filePath" ($fullUrl): $e');
          }


        } catch (e) {
          // Fängt Fehler wie Netzwerkprobleme, DNS-Fehler etc. ab, bevor eine Antwort kommt
          fail('❌ Failed to reach or get a response from "$filePath" ($fullUrl):\n$e');
        }
      });
    }
  });

  // Testgruppe für Textdateien
  group('Firebase Hosting Text Files', () {
    for (final filePath in textFilePaths) {
      test('File "$filePath" should be accessible and UTF-8 encoded', () async {
        final fullUrl = Uri.parse('$firebaseHostingBaseUrl$filePath');

        try {
          final response = await http.get(fullUrl);

          // 1. Prüfe den Statuscode
          expect(
            response.statusCode,
            200,
            reason: 'Expected status code 200 for $fullUrl. Received ${response.statusCode}. '
                'Body: ${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}',
          );

          // 2. Prüfe, ob der Content-Type Header auf Text hindeutet (optional)
          final contentType = response.headers['content-type'] ?? '';
          // Überprüfe auf gängige Text-Content-Types. Du kannst diese Liste erweitern.
          expect(
              contentType.startsWith('text/') || contentType == 'application/json' || contentType == 'application/xml', // JSON und XML sind auch oft lesbar
              isTrue,
              reason: 'Expected a text-like Content-Type for $fullUrl. Received "$contentType".'
          );


          // 3. Prüfe die UTF-8 Dekodierung (indem wir versuchen zu dekodieren)
          try {
            // Verwende bodyBytes und utf8.decode
            final String decodedBody = utf8.decode(response.bodyBytes);

            // Optional: Du könntest hier prüfen, ob der String nicht leer ist oder
            // ob er mit einem erwarteten Anfang beginnt etc.
            expect(decodedBody, isNotNull, reason: 'Decoded body should not be null');
            // expect(decodedBody.isNotEmpty, isTrue, reason: 'Decoded body should not be empty');

            print('✅ Success: "$filePath" ($fullUrl) is accessible and UTF-8 encoded.');

          } catch (e) {
            // Dieser Fehler tritt auf, wenn utf8.decode fehlschlägt
            fail('❌ Failed to decode "$filePath" ($fullUrl) as UTF-8:\n$e');
          }


        } catch (e) {
          // Fängt Fehler wie Netzwerkprobleme, DNS-Fehler etc. ab
          fail('❌ Failed to reach or get a response from "$filePath" ($fullUrl):\n$e');
        }
      });
    }
  });
}
