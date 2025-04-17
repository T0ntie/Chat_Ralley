import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'npc.dart';

class Backend {

  static Future<Map<String, dynamic>> loadStoryLineJson(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final jsonData = json.decode(jsonString);
    return jsonData;
  }

  static Future<List<NPC>> loadNPCs() async {
      //final alicePrompt = await rootBundle.loadString('assets/npc_prompts/alice.txt');
      final bozziPrompt = await rootBundle.loadString('assets/story/prompts/bozzi-prompt.txt');
      final storyLine = await loadStoryLineJson('assets/story/storyline.jsn');
      print ("the following story was loaded: ${storyLine['title']}");

      //final peziPrompt = await rootBundle.loadString('assets/npc_prompts/pezi.txt');
    return [
      NPC(
        name: "Alice im Wunderland",
        prompt: "Du bist Alice im Wunderland, und schickst manchmal Grüße von der Herzkönigin",
        position: LatLng(48.08418, 16.29050),
        icon: NPCIcon.unknown,
      ),
      NPC(
        name: "Bozzi im Wohnzimmer",
        prompt: bozziPrompt,
        position: LatLng(48.090382361745675, 16.296814606890685),
        icon: NPCIcon.alert,
      ),
      NPC(
        name: "Pezi",
        prompt: "Mechtlers Wille geschehe",
        position: LatLng(48.248951, 16.369782),
        icon: NPCIcon.unknown,
      ),
    ];
  }
}
