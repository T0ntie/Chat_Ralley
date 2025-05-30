import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseHosting {
  static const FireBaseHostingURI = 'https://storytrail-e3bf7.web.app/';

  static Widget loadImageWidget(String url, {BoxFit fit = BoxFit.cover}) {
    final fullUrl = '$FireBaseHostingURI$url';

    return CachedNetworkImage(
      imageUrl: fullUrl,
      placeholder:
          (context, _) => const Center(child: CircularProgressIndicator()),
      errorWidget:
          (context, _, __) =>
      const Icon(Icons.broken_image, color: Colors.white70),
      fit: fit,
    );
  }

  static Widget loadSvgWidget(String url, {
    ColorFilter? colorFilter,
    double width = 24,
    double height = 24,
  }) {
    final fullUrl = '$FireBaseHostingURI$url';
    return SvgPicture.network(
      fullUrl,
      colorFilter: colorFilter,
      placeholderBuilder: (context) => const CircularProgressIndicator(),
      width: width,
      height: height,
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

    print('📤 Starte Request an: $completeUrl');

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

class FirestoreService {

  //fixme check of das passt
  static Future<void> saveGameState({
    required String trailId,
    required Map<String, dynamic> jsonGameState,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Benutzer nicht angemeldet");

    final docRef = FirebaseFirestore.instance
        .collection('gameStates')
        .doc(uid)
        .collection('saves')
        .doc(trailId);

    await docRef.set({
      'saveTime': FieldValue.serverTimestamp(),
      'data': jsonGameState,
    });

    print("Spielstand für trailId '$trailId' gespeichert.");
  }

  static Future<Map<String, dynamic>?> loadGameState(String trailId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final docRef = FirebaseFirestore.instance
        .collection('gameStates')
        .doc(uid)
        .collection('saves')
        .doc(trailId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return null;

    return snapshot.data()?['data'];
  }

}
