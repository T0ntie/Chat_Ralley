import 'package:hello_world/engine/npc.dart';
import 'package:flutter/material.dart';

class ResourceIcons {
  static const IconData unknown = Icons.not_listed_location;
  static const IconData identified = Icons.location_on;
  static const IconData hotspot = Icons.flag;
  static const IconData chatBubble = Icons.feedback;
  static const IconData mapHeading = Icons.explore;
  static const IconData centerLocation = Icons.my_location;
  static const IconData playerPosition = Icons.navigation;
}

class ResourceColors {
  static const Color unknown = Colors.grey;
  static const Color identified = Colors.black;
  static const Color nearby = Colors.redAccent;
  static const Color hotspot = Colors.green;
  static const Color chatBubble = Colors.blue;
  static const Color mapHeadingTrue = Colors.deepOrange;
  static const Color mapHeadingFalse = Colors.black;
  static const Color playerPosition = Colors.blue;
}

class ResourceSizes {
  static const double npcIconSize = 40.0;
  static const double hotspotSize = 30.0;
  static const double playerPositionSize = 30.0;
}

Icon buildIcon(IconData iconData, {Color color = Colors.black, double size = 24.0}) {
  return Icon(iconData, color: color, size: size);
}

class AppIcons {
  static Icon npcIcon(NPCIcon type) {
    switch (type) {
      case NPCIcon.unknown:
        return buildIcon(ResourceIcons.unknown, color: ResourceColors.unknown, size: ResourceSizes.npcIconSize);
      case NPCIcon.identified:
        return buildIcon(ResourceIcons.identified, color: ResourceColors.identified, size: ResourceSizes.npcIconSize);
      case NPCIcon.nearby:
        return buildIcon(ResourceIcons.identified, color: ResourceColors.nearby, size: ResourceSizes.npcIconSize);
      case NPCIcon.unknown_nearby:
        return buildIcon(ResourceIcons.unknown, color: ResourceColors.nearby, size: ResourceSizes.npcIconSize);
    }
  }

  static Icon hotspot() => buildIcon(ResourceIcons.hotspot, color: ResourceColors.hotspot, size: ResourceSizes.hotspotSize);
  static Icon chatBubble() => buildIcon(ResourceIcons.chatBubble, color: ResourceColors.chatBubble, size: ResourceSizes.npcIconSize);
  static Icon mapHeading(bool isBasedOnHeading) => buildIcon(
    ResourceIcons.mapHeading,
    color: isBasedOnHeading ? ResourceColors.mapHeadingTrue : ResourceColors.mapHeadingFalse,
    size: ResourceSizes.npcIconSize,
  );
  static Icon centerLocation() => buildIcon(ResourceIcons.centerLocation);
  static Icon playerPosition() => buildIcon(ResourceIcons.playerPosition, color: ResourceColors.playerPosition, size: ResourceSizes.playerPositionSize);
}
