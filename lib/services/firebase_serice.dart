import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:aitrailsgo/services/log_service.dart';

class FirebaseHosting {
  static const fireBaseHostingURI = 'https://aitrailsgo.web.app/';

  static Widget loadImageWidget(String url, {BoxFit fit = BoxFit.cover}) {
    final fullUrl = '$fireBaseHostingURI$url';

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

  static Widget loadSvgWidget(
    String url, {
    ColorFilter? colorFilter,
    double width = 24,
    double height = 24,
  }) {
    final fullUrl = '$fireBaseHostingURI$url';
    return SvgPicture.network(
      fullUrl,
      colorFilter: colorFilter,
      placeholderBuilder: (context) => const CircularProgressIndicator(),
      width: width,
      height: height,
    );
  }

  static Future<String> loadStringFromUrl(String url) async {
    final String completeUrl = '$fireBaseHostingURI$url';

    final http.Response response;
    try {
      response = await http.get(Uri.parse(completeUrl));
    } catch (e, stackTrace) {
      log.e(
        '❌ failed to get http request from "$completeUrl".',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    if (response.statusCode == 200) {
      try {
        return utf8.decode(response.bodyBytes);
      } catch (e, stackTrace) {
        log.e(
          '❌ failed to decode response from "$completeUrl".',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    } else {
      log.e(
        '❌ Received error code from "$completeUrl": HTTP ${response.statusCode}',
        stackTrace: StackTrace.current,
      );
      throw Exception(
        '❌ Received error code from "$completeUrl": HTTP ${response.statusCode}',
      );
    }
  }

  static Future<Map<String, dynamic>> loadJsonFromUrl(String url) async {
    final String completeUrl = '$fireBaseHostingURI$url';

    final http.Response response;
    try {
      response = await http.get(Uri.parse(completeUrl));
    } catch (e, stackTrace) {
      log.e(
        '❌ failed to get http request from "$completeUrl".',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    if (response.statusCode == 200) {
      try {
        return json.decode(utf8.decode(response.bodyBytes));
      } catch (e, stackTrace) {
        log.e(
          '❌ failed to decode response from "$completeUrl".',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    } else {
      log.e(
        '❌ Received error code from "$completeUrl": HTTP ${response.statusCode}',
        stackTrace: StackTrace.current,
      );
      throw Exception(
        '❌ Received error code from "$completeUrl": HTTP ${response.statusCode}',
      );
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
    if (uid == null) {
      log.e("❌ User not authenticated.", stackTrace: StackTrace.current);
      throw Exception("❌ User not authenticated.");
    }

    final docRef = FirebaseFirestore.instance
        .collection('gameStates')
        .doc(uid)
        .collection('saves')
        .doc(trailId);

    await docRef.set({
      'saveTime': FieldValue.serverTimestamp(),
      'data': jsonGameState,
    });

    log.i("✅ Spielstand für trailId '$trailId' gespeichert.");
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
    if (!snapshot.exists) {
      log.d("Kein Spielstand für trailId '$trailId' gefunden.");
      return null;
    }

    return snapshot.data()?['data'];
  }
}
