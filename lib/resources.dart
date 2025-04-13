import 'package:hello_world/npc.dart';
import 'package:flutter/material.dart';



class Resources{

  static  IconData _getIconFromNPCIcon(NPCIcon iconType) {
    switch (iconType) {
      case NPCIcon.unknownIcon:
        return Icons.not_listed_location;
      case NPCIcon.dangerIcon:
        return Icons.fmd_bad;
      case NPCIcon.friendlyIcon:
        return Icons.thumb_up;
      default:
        return Icons.help;
    }
  }

    static Icon getNPCIcon(NPCIcon iconType, Color iconColor){
    return Icon(
          _getIconFromNPCIcon(iconType),
          color: iconColor, // Die Farbe des Pins
          size: 30.0, // Die Größe des Markers
    );
  }
}