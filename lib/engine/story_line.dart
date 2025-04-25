import 'package:hello_world/engine/hotspot.dart';

import 'npc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class StoryLine {
  final String scenarioId;
  final String title;
  final List<Npc> npcs;
  final List<Hotspot> hotspots;
  final Map<String, bool> flags;

  static const storyLineAsset = 'assets/story/storyline.json';

  StoryLine({required this.scenarioId, required this.title, required this.npcs, required this.hotspots, required this.flags});

  static Future<StoryLine> fromJsonAsync(Map<String, dynamic> json) async{
    try {
      final npcsJson = json['npcs'] as List;
      final npcs = await Future.wait(npcsJson.map((e) => Npc.fromJsonAsync(e)));
      final hotspotsJsn = json['hotspots'] as List;
      final hotspots = hotspotsJsn.map((e) => Hotspot.fromJson(e)).toList();
      final flags = (json['flags'] as Map<String, dynamic>).cast<String, bool>();
      return StoryLine(
        scenarioId: json['scenarioId'],
        title: json['title'],
        npcs: npcs,
        hotspots: hotspots,
        flags: flags,
      );
    }catch (e, stack) {
      print('❌ Fehler im Json der Storyline:\n$e\n$stack');
      rethrow;
    }
  }

  static Future<StoryLine> loadStoryLine() async {
    try {
      final jsonString = await rootBundle.loadString(storyLineAsset);
      final jsonData = json.decode(jsonString);
      return await StoryLine.fromJsonAsync(jsonData);
    } catch (e, stack) {
      print('❌ Fehler beim Laden der Storyline:\n$e\n$stack');
      rethrow;
    }
  }

}