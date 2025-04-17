import 'package:hello_world/npc.dart';
import 'package:flutter/material.dart';



class Resources{

  static  IconData _getIconFromNPCIcon(NPCIcon iconType) {
    switch (iconType) {
      case NPCIcon.unknown:
        return Icons.not_listed_location;
      case NPCIcon.identified:
        return Icons.fmd_bad;
      case NPCIcon.alert:
        return Icons.thumb_up;
    }
  }

  static Icon createIconforNPC(NPCIcon iconType) {
    switch(iconType) {
      case NPCIcon.unknown:
          return Icon(Icons.not_listed_location, color: Colors.grey, size: 40, );
      case NPCIcon.identified:
        return Icon(Icons.fmd_bad, color: Colors.black, size: 40, );
      case NPCIcon.alert:
        return Icon(Icons.fmd_bad, color: Colors.redAccent, size: 40, );

    }
  }

  static Icon getNPCIcon(NPCIcon iconType){
/*
    return Icon(
          _getIconFromNPCIcon(iconType),
          color: iconColor, // Die Farbe des Pins
          size: 40.0, // Die Größe des Markers
);
*/
    return createIconforNPC(iconType);

  }

  static Icon getChatBubbleIcon()
  {
    return Icon(
      Icons.feedback,
      color: Colors.blue, // Die Farbe der Sprechblase
      size: 40.0, // Die Größe der Sprechblase
    );
  }

}