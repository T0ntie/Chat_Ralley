import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'conversation.dart';

enum NPCIcon { unknown, identified, alert }

class Npc {
  final String name;
  final String prompt;
  LatLng position;
  late NPCIcon icon;
  late String displayName;
  double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  late Conversation currentConversation;
  final double conversationDistance = 20.0; //how close you need to be to communicate

  Npc({
    required this.name,
    required this.prompt,
    required this.position,
    Conversation? currentConversation,
  }) {
    this.currentConversation = Conversation(this);
    this.displayName = name;
    this.icon = NPCIcon.unknown;
  }

  static Future<Npc> fromJsonAsync(Map<String, dynamic> json) async {
    try {
      final promptFile = json['prompt'] as String;
      final promptText = await rootBundle.loadString(
          'assets/story/${promptFile}');

      return Npc(
        name: json['name'],
        position: LatLng(
            (json['position']['lat'] as num).toDouble(),
            (json['position']['lng'] as num).toDouble()
        ),
        prompt: promptText,
      );
    }catch (e, stack) {
      print('❌ Fehler im Json der Npcs:\n$e\n$stack');
      rethrow;
    }
  }

  bool canCommunicate()
  {
    return (currentDistance < conversationDistance);
  }

  void updatePlayerPosition(LatLng playerPosition) {
    print("updating player position");
    this.playerPosition = playerPosition;
    currentDistance = Distance().as(LengthUnit.Meter, position, playerPosition);
  }

  void startNewConversation(Conversation conversation) {
    currentConversation = conversation;
  }
}
