import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:latlong2/latlong.dart';

import 'conversation.dart';

enum NPCIcon { unknownIcon, friendlyIcon, dangerIcon }

class NPC {
  final String name;
  final String prompt;
  LatLng position;
  NPCIcon icon;
  Color iconColor;
  String displayName;
  double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  late Conversation currentConversation;

  NPC({
    required this.name,
    required this.prompt,
    required this.position,
    required this.icon,
    required this.iconColor,
    this.displayName = "uknown",
    Conversation? currentConversation,
  }) {
    this.currentConversation = Conversation(this);
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
