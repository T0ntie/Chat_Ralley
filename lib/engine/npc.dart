
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'conversation.dart';
import '../actions/action.dart';

enum NPCIcon { unknown, identified, nearby, unknown_nearby }

class Npc {
  final String name;
  final String prompt;
  String imageAsset;
  final String unknownImageAsset = "images/unknown.png";
  LatLng position;
  bool isVisible;
  bool isRevealed;
  bool isMoving = false;
  late LatLng toPosition;
  DateTime lastPositionUpdate = DateTime.now();
  double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  late Conversation currentConversation;
  final double conversationDistance = 20.0; //how close you need to be to communicate
  final double speed = 5 * 1000 / 3600;
  List<Action> actions = [];

  Npc({
    required this.name,
    required this.imageAsset,
    required this.prompt,
    required this.position,
    required this.actions,
    required this.isVisible,
    required this.isRevealed,
  }) {
    this.currentConversation = Conversation(this);
    this.toPosition = position;
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
        imageAsset: json['image'],
        isVisible: json['visible'] as bool? ?? true,
        isRevealed: json['revealed'] as bool? ?? false,
        actions: actions,
      );
    }catch (e, stack) {
      print('❌ Fehler im Json der Npcs:\n$e\n$stack');
      rethrow;
    }
  }

  void appear() {
    isVisible = true;
  }

  void reveal() {
    isVisible = true;
    isRevealed = true;
  }

  void moveTo(LatLng toPosition) {
    this.toPosition = toPosition;
    isMoving = true;
    lastPositionUpdate = DateTime.now();
  }

  String get displayImageAsset {
    return isRevealed ? imageAsset : unknownImageAsset;
  }
  String get displayName {
    return isRevealed ? name : "Unbekannt";
  }
  LatLng get currentPosition {
    if (! isMoving) return position;

    final now = DateTime.now();
    final timeDiffSeconds = now.difference(lastPositionUpdate).inMilliseconds / 1000.0;
    final distanceToTravel = speed * timeDiffSeconds;
    final distance = const Distance().as(LengthUnit.Meter, position, toPosition!);
    if (distanceToTravel > distance) {
      isMoving = false;
      position = toPosition;
      return position;
    }
    final fraction = distanceToTravel/distance;
    final newLat = position.latitude + (toPosition.latitude - position.latitude) * fraction;
    final newLng = position.longitude + (toPosition.longitude - position.longitude) * fraction;
    return LatLng(newLat, newLng);
  }

  NPCIcon get icon {
    if (isVisible) {
      if (isRevealed) {
        if (canCommunicate()) {
          return NPCIcon.nearby;
        } else return NPCIcon.identified;
      } else {
        if (canCommunicate()) {
          return NPCIcon.unknown_nearby;
        } else return NPCIcon.unknown;
      }
    }
    return NPCIcon.unknown;
  }

  bool canCommunicate()
  {
    return (currentDistance < conversationDistance);
  }

  //fixme mach currentDistance zum getter ohne updatePlayerPosition zu benötigen
  void updatePlayerPosition(LatLng playerPosition) {
    print("updating player position");
    this.playerPosition = playerPosition;
    currentDistance = Distance().as(LengthUnit.Meter, currentPosition, playerPosition);
  }

  void startNewConversation(Conversation conversation) {
    currentConversation = conversation;
  }
}
