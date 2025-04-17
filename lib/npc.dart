import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:latlong2/latlong.dart';

import 'conversation.dart';

enum NPCIcon { unknown, identified, alert }

class NPC {
  final String name;
  final String prompt;
  LatLng position;
  NPCIcon icon;
  late String displayName;
  double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  late Conversation currentConversation;
  final double conversationDistance = 20.0; //how close you need to be to communicate

  NPC({
    required this.name,
    required this.prompt,
    required this.position,
    required this.icon,
    Conversation? currentConversation,
  }) {
    this.currentConversation = Conversation(this);
    this.displayName = name;
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
