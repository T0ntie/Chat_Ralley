
import 'package:hello_world/actions/npc_action.dart';
import 'package:hello_world/engine/game_element.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'conversation.dart';

import 'dart:math';

enum NPCIcon { unknown, identified, nearby, unknown_nearby }

class Npc extends GameElement{
  final String prompt;
  String imageAsset;
  static final String unknownImageAsset = "images/unknown.png";
  bool isRevealed;
  bool isMoving = false;
  bool isFollowing = false;
  bool hasSomethingToSay = false;
  static final followingDistance = 5.0;
  late LatLng toPosition;
  List <LatLng> movementPath = [];
  DateTime lastPositionUpdate = DateTime.now();
  //double currentDistance = double.infinity;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  late Conversation currentConversation;
   //how close you need to be to communicate
  double speed; //in m/s


  Npc({
    required super.name,
    required this.imageAsset,
    required this.prompt,
    required super.position,
    required super.actions,
    required super.isVisible,
    required this.isRevealed,
    required this.speed, //in km/h
  }) {
    this.currentConversation = Conversation(this);
    this.toPosition = position;
    this.speed = speed * 1000 /3600;
  }

  static Future<Npc> fromJsonAsync(Map<String, dynamic> json) async {
    try {
      final promptFile = json['prompt'] as String;
      final promptText = await rootBundle.loadString(
          'assets/story/${promptFile}');
      final actionsJson = json['actions'] as List? ?? [];
      final actions = actionsJson.map((a) => NpcAction.fromJson(a)).toList();

      //check vor valid position
      final pos = json['position'];
      if (pos is! Map || pos['lat'] == null || pos['lng'] == null) {
        throw FormatException('Ungültige Positionsdaten in stryline.jsn: $pos bei ${json['name']}');
      }

      return Npc(
        name: json['name'],
        position: LatLng(
            (json['position']['lat'] as num).toDouble(),
            (json['position']['lng'] as num).toDouble(),
        ),
        prompt: promptText,
        imageAsset: json['image'] as String? ?? unknownImageAsset,
        isVisible: json['visible'] as bool? ?? true,
        isRevealed: json['revealed'] as bool? ?? false,
        speed: (json['speed'] as num?)?.toDouble() ?? 5.0,
        actions: actions,
      );
    }catch (e, stack) {
      print('❌ Fehler im Json der Npcs:\n$e\n$stack');
      rethrow;
    }
  }



  void reveal() {
    isVisible = true;
    isRevealed = true;
  }

  void spawn() {
    final random = Random();
    // Ein kleiner zufälliger Offset in Grad (ca. 0.00005 ~ 5 Meter)
    final offsetLat = (random.nextDouble() - 0.5) * 0.0001;
    final offsetLng = (random.nextDouble() - 0.5) * 0.0001;

    position = LatLng(
      playerPosition.latitude + offsetLat,
      playerPosition.longitude + offsetLng,
    );
  }

  void moveTo(LatLng toPosition) {
    if (isMoving){
      position = currentPosition;
    }
    this.toPosition = toPosition;
    isMoving = true;
    isFollowing = false;
    lastPositionUpdate = DateTime.now();
  }

  void moveAlong(List<LatLng> path) {
    if (isMoving){
      position = currentPosition;
    }
    movementPath = List.from(path);
    this.toPosition = movementPath.removeAt(0);
    isMoving = true;
    isFollowing = false;
    lastPositionUpdate = DateTime.now();
  }

  void startFollowing() {
    if (isMoving){
      position = currentPosition;
    }
    this.toPosition = playerPosition;
    this.movementPath = [];
    isFollowing = true;
    isMoving = true;
    lastPositionUpdate = DateTime.now();
  }

  void stopMoving() {
    position = currentPosition;
    isFollowing = false;
    isMoving = false;
    this.movementPath = [];
  }

  void talk(String repsondTo) async{
    hasSomethingToSay = true;
    currentConversation.addTriggerMessage(repsondTo);
  }

  void behave(String directive) {
    currentConversation.addSystemMessage(directive);
  }

  double get currentDistance  {
    return Distance().as(LengthUnit.Meter, currentPosition, playerPosition);
  }

  String get displayImageAsset {
    return isRevealed ? imageAsset : unknownImageAsset;
  }
  String get displayName {
    return isRevealed ? name : "Unbekannt";
  }

  LatLng get currentPosition {
    if (!isMoving) return position;
    final now = DateTime.now();
    final timeDiffSeconds = now.difference(lastPositionUpdate).inMilliseconds / 1000.0;
    final distanceToTravel = speed * timeDiffSeconds;
    final distance = const Distance().as(LengthUnit.Meter, position, toPosition);

    if (distanceToTravel > distance) {
      position = toPosition;
      if (movementPath.isNotEmpty){
        toPosition = movementPath.removeAt(0);
        lastPositionUpdate = now;
        return currentPosition; //rekursiver Aufruf
      }
      isMoving = false;
      return position;
    }
    final fraction = distanceToTravel/distance;
    final newLat = position.latitude + (toPosition.latitude - position.latitude) * fraction;
    final newLng = position.longitude + (toPosition.longitude - position.longitude) * fraction;
    final interpolatedPosition = LatLng(newLat, newLng);

    //wenn npc nahe genug beim player ist bleibt er stehen
    if (isFollowing) {
      final distanceToPlayer = const Distance().as(LengthUnit.Meter, interpolatedPosition, playerPosition);
      if (distanceToPlayer < followingDistance) {
        isMoving = false;
        position = interpolatedPosition;
        return interpolatedPosition;
      }
    }
    return interpolatedPosition;
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
    return (currentDistance < GameEngine.conversationDistance);
  }

  void updatePlayerPosition(LatLng playerPosition) {
    this.playerPosition = playerPosition;
    if (isFollowing) {
      if (currentDistance > followingDistance) {
        lastPositionUpdate = DateTime.now();
        toPosition = this.playerPosition;
        isMoving = true;
      }
    }
    if (currentDistance < GameEngine.conversationDistance){
      GameEngine.instance.registerApproach(this);
    }
  }
}
