import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'conversation.dart';
import 'action.dart';

enum NPCIcon { unknown, identified, alert }

class Npc {
  final String name;
  final String prompt;
  LatLng position;
  late NPCIcon icon;
  late String displayName;
  bool isVisible;
  double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  late Conversation currentConversation;
  final double conversationDistance = 20.0; //how close you need to be to communicate

  List<Action> actions = [];

  Npc({
    required this.name,
    required this.prompt,
    required this.position,
    required this.actions,
    required this.isVisible,
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
      final actionsJson = json['actions'] as List;
      final actions = await Future.wait(actionsJson.map((a) => Action.fromJsonAsync(a)));
      return Npc(
        name: json['name'],
        position: LatLng(
            (json['position']['lat'] as num).toDouble(),
            (json['position']['lng'] as num).toDouble()
        ),
        prompt: promptText,
        isVisible: json['visible'] as bool,
        actions: actions,
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
