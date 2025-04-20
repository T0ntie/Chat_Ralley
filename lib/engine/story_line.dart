import 'package:hello_world/engine/hotspot.dart';

import 'npc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class StoryLine {
  final String scenarioId;
  final String title;
  final List<Npc> npcs;
  final List<Hotspot> hotspots;

  StoryLine({required this.scenarioId, required this.title, required this.npcs, required this.hotspots});

  static Future<StoryLine> fromJsonAsync(Map<String, dynamic> json) async{
    try {
      final npcsJson = json['npcs'] as List;
      final npcs = await Future.wait(npcsJson.map((e) => Npc.fromJsonAsync(e)));
      final hotspotsJsn = json['hotspots'] as List;
      final hotspots = hotspotsJsn.map((e) => Hotspot.fromJson(e)).toList();
      return StoryLine(
        scenarioId: json['scenarioId'],
        title: json['title'],
        npcs: npcs,
        hotspots: hotspots,
      );
    }catch (e, stack) {
      print('❌ Fehler im Json der Storyline:\n$e\n$stack');
      rethrow;
    }
  }

  static Future<StoryLine> loadStoryLine() async {
    try {
      final jsonString = await rootBundle.loadString(
          'assets/story/storyline.jsn');
      final jsonData = json.decode(jsonString);
      return await StoryLine.fromJsonAsync(jsonData);
    } catch (e, stack) {
      print('❌ Fehler beim Laden der Storyline:\n$e\n$stack');
      rethrow;
    }
  }

}