import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';

class FirebaseHosting {
  static const FireBaseHostingURI = 'https://storytrail-e3bf7.web.app/';
  static final Map<String, Uint8List> _imageCache = {};

  static Widget loadImageWidget(String url, {BoxFit fit = BoxFit.contain}) {
    return FutureBuilder<Uint8List>(
      future: loadImageBytes(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Icon(Icons.broken_image, color: Colors.white70);
        } else {
          return Image.memory(
            snapshot.data!,
            fit: fit,
          );
        }
      },
    );
  }


  static Future<Uint8List> loadImageBytes(String url) async {
    final String completeUrl = '$FireBaseHostingURI$url';

    if (_imageCache.containsKey(completeUrl)) {
      return _imageCache[completeUrl]!;
    }

    try {
      final response = await http.get(Uri.parse(completeUrl));
      if (response.statusCode == 200) {
        _imageCache[completeUrl] = response.bodyBytes;
        return response.bodyBytes;
      } else {
        throw Exception(
          'Fehler beim Laden [$completeUrl]: HTTP ${response.statusCode}',
        );
      }

    } catch (e, stack) {
      print('❌ Fehler beim Laden von Bilddaten aus $completeUrl:\n$e\n$stack');
      rethrow;
    }
  }

  static Future<String> loadStringFromUrl(String url) async {
    final String completeUrl = '$FireBaseHostingURI$url';

    try {
      final response = await http.get(Uri.parse(completeUrl));
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      } else {
        throw Exception(
          'Fehler beim Laden [$completeUrl]: HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      print('❌ Fehler beim Laden der Datei $completeUrl:\n$e\n$stack');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> loadJsonFromUrl(String url) async {
    final String completeUrl = '${FireBaseHostingURI}${url}';

    try {
      final response = await http.get(Uri.parse(completeUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonData;
      } else {
        throw Exception(
          'Fehler beim Laden [$completeUrl]: HTTP ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      print('❌ Fehler beim Laden von JSON aus $completeUrl:\n$e\n$stack');
      rethrow;
    }
  }
}
