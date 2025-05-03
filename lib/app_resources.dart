//import 'package:flutter_svg/svg.dart';
import 'package:hello_world/engine/npc.dart';
import 'package:flutter/material.dart';

class ResourceIcons {
  static const IconData unknown = Icons.not_listed_location;
  static const IconData identified = Icons.location_on;
  static const IconData hotspot = Icons.flag;
  static const IconData chatBubble = Icons.feedback;
  static const IconData mapHeadingOn = Icons.explore;
  static const IconData mapHeadingOff = Icons.explore_off;
  static const IconData centerLocation = Icons.my_location;
  static const IconData playerPosition = Icons.navigation;
  static const IconData notification = Icons.info_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData retry = Icons.refresh;
}

class ResourceColors {

  //Map Markers
  static Color seed = Colors.green;
  static Color unknownNpc = Colors.black;
  static Color identifiedNpc = Colors.black;
  static Color nearbyNpc = Color(0xFFD50000);
  static Color npcName = Colors.black;
  static Color hotspotMarker = Color(0xFF00C853);
  static Color hotspotCircle = Color(0xFF00C853);
  static Color playerPositionMarker = Color(0xFF2962FF);
  static Color playerPositionCircle = Color(0xFF2962FF);
  static Color playerPositionFadeoutCircle = Colors.white;
  static Color npcTalkIndicator = Colors.blue;

  static Color mapHeading(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color notification(BuildContext context) => Theme.of(context).colorScheme.onTertiaryContainer;
  static Color notificationBackground(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
  static Color notificationMessage(BuildContext context) => Theme.of(context).colorScheme.onPrimaryContainer;
  static Color notificationTitle(BuildContext context) => Theme.of(context).colorScheme.onPrimaryFixedVariant;

  //chatpage
  static Color messageFieldBackground(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color userChatBubble(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
  static Color assistantChatBubble(BuildContext context) => Theme.of(context).colorScheme.tertiaryContainer;
  static Color messageSendButton(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color messageDialogBackground(BuildContext context) => Theme.of(context).colorScheme.surface;

  //snackbar
  static Color errorSnack(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color successSnack(BuildContext context) => Color(0xFF00C853); //Theme.of(context).colorScheme.primaryContainer;
  static Color errorMessage(BuildContext context) => Theme.of(context).colorScheme.error;

  //ActionTestingPanel
  static Color tile(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
}
class ResourceSizes {
  static const double npcIconSize = 40.0;
  static const double hotspotSize = 30.0;
  static const double playerPositionSize = 40.0;
}

class ResourceImages {
  static Image walkieTakie(BuildContext context) => Image.asset('assets/story/images/walkie-talkie.png', fit: BoxFit.cover);
}

Icon buildIcon(IconData iconData, {Color color = Colors.black, double size = 24.0}) {
  return Icon(iconData, color: color, size: size);
}
/*

SvgPicture buildSVGIcon({required String assetName, double width = 24.0, double height = 24.0}) {
  return SvgPicture.asset(assetName, width: width, height: height);
}

*/
class AppIcons {
  static Icon npc(BuildContext context, NPCIcon type) {
    switch (type) {
      case NPCIcon.unknown:
        return buildIcon(ResourceIcons.unknown, color: ResourceColors.unknownNpc, size: ResourceSizes.npcIconSize);
      case NPCIcon.identified:
        return buildIcon(ResourceIcons.identified, color: ResourceColors.identifiedNpc, size: ResourceSizes.npcIconSize);
      case NPCIcon.nearby:
        return buildIcon(ResourceIcons.identified, color: ResourceColors.nearbyNpc, size: ResourceSizes.npcIconSize);
      case NPCIcon.unknown_nearby:
        return buildIcon(ResourceIcons.unknown, color: ResourceColors.nearbyNpc, size: ResourceSizes.npcIconSize);
    }
  }

  static Icon hotspot(BuildContext context) => buildIcon(ResourceIcons.hotspot, color: ResourceColors.hotspotMarker, size: ResourceSizes.hotspotSize);
  static Icon chatBubble(BuildContext context) => buildIcon(ResourceIcons.chatBubble, color: ResourceColors.npcTalkIndicator, size: ResourceSizes.npcIconSize);
  static Icon mapHeading(BuildContext context, bool isHeadingActivated) => buildIcon(
    isHeadingActivated ? ResourceIcons.mapHeadingOn : ResourceIcons.mapHeadingOff,
    color: ResourceColors.mapHeading(context),
    size: ResourceSizes.npcIconSize,
  );
  static Icon centerLocation(BuildContext context) => buildIcon(ResourceIcons.centerLocation);
  static Icon playerPosition = buildIcon(ResourceIcons.playerPosition, color: ResourceColors.playerPositionMarker, size: ResourceSizes.playerPositionSize);
  static Icon notification(BuildContext context) => buildIcon(ResourceIcons.notification, color: ResourceColors.notification(context), size: 40);

  static Icon error(BuildContext context) => buildIcon(ResourceIcons.error, color: ResourceColors.errorMessage(context), size: 64);
  static Icon retry(BuildContext context) => buildIcon(ResourceIcons.retry);
  
//  static SvgPicture walkie(BuildContext context) => buildSVGIcon(assetName: "assets/story/icons/walkie-talkie.svg");
}