import 'npc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class StoryLine {
  final String scenarioId;
  final String title;
  final List<Npc> npcs;

  StoryLine({required this.scenarioId, required this.title, required this.npcs});

  static Future<StoryLine> fromJsonAsync(Map<String, dynamic> json) async{
    final npcsJson = json['npcs'] as List;
    final npcs = await Future.wait(npcsJson.map((e) => Npc.fromJsonAsync(e)));
    return StoryLine (
      scenarioId: json['scenarioId'],
      title: json['title'],
      npcs: npcs,
    );
  }

  static Future<StoryLine> loadStoryLine() async {
    final jsonString = await rootBundle.loadString('assets/story/storyline.jsn');
    final jsonData = json.decode(jsonString);
    return await StoryLine.fromJsonAsync(jsonData);
  }

}