import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';

class FirebaseHosting {
  static const FireBaseHostingURI = 'https://storytrail-e3bf7.web.app/';

  static Widget loadImageWidget(String url, {BoxFit fit = BoxFit.cover}) {
    final fullUrl = '$FireBaseHostingURI$url';

    return CachedNetworkImage(
      imageUrl: fullUrl,
      placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, _, __) => const Icon(Icons.broken_image, color: Colors.white70),
      fit: fit,
    );
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