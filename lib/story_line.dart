import 'npc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class StoryLine {
  final String scenarioId;
  final String title;
  final List<Npc> npcs;

  StoryLine({required this.scenarioId, required this.title, required this.npcs});

  static Future<StoryLine> fromJsonAsync(Map<String, dynamic> json) async{
    try {
      final npcsJson = json['npcs'] as List;
      final npcs = await Future.wait(npcsJson.map((e) => Npc.fromJsonAsync(e)));
      return StoryLine(
        scenarioId: json['scenarioId'],
        title: json['title'],
        npcs: npcs,
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