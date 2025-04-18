import 'package:hello_world/npc.dart';
import 'package:flutter/material.dart';



class Resources{

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
  static Icon getMapHeadingIcon(bool isMapHeadingBasedOrientation) {
    return Icon(
      Icons.explore,
      size: 40,
      color: isMapHeadingBasedOrientation ? Colors.deepOrange : Colors.black,
    );
  }
  static Icon centerLocationIcon()
  {
    return Icon(Icons.my_location);
  }

  static Icon playerPositionIcon()
  {
    return Icon(
      Icons.navigation,
      color: Colors.blue, // Die Farbe des Pins
      size: 30.0, // Die Größe des Markers
    );
  }
}