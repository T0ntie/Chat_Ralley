import 'package:hello_world/actions/npc_action.dart';
import 'package:hello_world/engine/game_element.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/prompt.dart';
import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';
import 'conversation.dart';

import 'dart:math';

enum NPCIcon { unknown, identified, nearby, unknown_nearby }

class Npc extends GameElement {
  final Prompt prompt;
  final String? iconAsset;

  bool hasSomethingToSay = false;

  List<NpcAction> actions = [];

  late Conversation currentConversation;

  final MovingBehavior movingBehavior;

  Npc({
    required super.name,
    required super.imageAsset,
    required this.prompt,
    required super.position, //fixme
    required this.actions,
    required super.isVisible,
    required super.isRevealed,
    required speed, //in km/h /fixme
    required this.iconAsset,
  }) :movingBehavior = MovingBehavior(
         currentBasePosition: position,
         toPosition: position,
         speedInKmh: speed,
       )
  {
    this.currentConversation = Conversation(this);
  }

  static Future<Npc> fromJsonAsync(Map<String, dynamic> json) async {
    try {
      final promptFile = json['prompt'] as String;
      Prompt prompt = await Prompt.createPrompt(promptFile);
      final actionsJson = json['actions'] as List? ?? [];
      final actions = actionsJson.map((a) => NpcAction.fromJson(a)).toList();

      final LatLng position = StoryLine.positionFromJson(json);
      return Npc(
        name: json['name'],
        position: position,
        prompt: prompt,
        imageAsset: json['image'] as String? ?? GameElement.unknownImageAsset,
        isVisible: json['visible'] as bool? ?? true,
        isRevealed: json['revealed'] as bool? ?? false,
        speed: (json['speed'] as num?)?.toDouble() ?? 5.0,
        iconAsset: json['iconAsset'] as String?,
        actions: actions,
      );
    } catch (e, stack) {
      print('❌ Fehler im Json der Npcs:\n$e\n$stack');
      rethrow;
    }
  }

  void reveal() {
    isVisible = true;
    isRevealed = true;
  }

  void spawn(double distance) {
    movingBehavior.spawn(distance);
  }


  void leadTo(LatLng toPosition) {
    movingBehavior.leadTo(toPosition);
  }

  void moveTo(LatLng toPosition) {
    movingBehavior.moveTo(toPosition);
  }

  void moveAlong(List<LatLng> path) {
    movingBehavior.moveAlong(path);
  }

  void leadAlong(List<LatLng> path) {
    movingBehavior.leadAlong(path);
  }

  void startFollowing() {
    movingBehavior.startFollowing();
  }

  void stopMoving() {
    movingBehavior.stopMoving();
  }

  void stopTalking() async {
    currentConversation.finishConversation();
  }

  void talk(String repsondTo) async {
    hasSomethingToSay = true;
    currentConversation.addTriggerMessage(repsondTo);
  }

  void injectTaggedPrompts(String tag) async {
    String content = prompt.getTaggedPrompt(tag);
    currentConversation.addSystemMessage(content);
  }

  void behave(String directive) {
    currentConversation.addSystemMessage(directive);
  }

  double get currentDistance {
    return movingBehavior.currentDistance;
  }

  String get displayName {
    return isRevealed ? name : "Unbekannt";
  }

  LatLng get currentPosition {
    return movingBehavior.currentPosition;
  }

  NPCIcon get icon {
    if (isVisible) {
      if (isRevealed) {
        if (isInCommunicationDistance()) {
          return NPCIcon.nearby;
        } else
          return NPCIcon.identified;
      } else {
        if (isInCommunicationDistance()) {
          return NPCIcon.unknown_nearby;
        } else
          return NPCIcon.unknown;
      }
    }
    return NPCIcon.unknown;
  }

  bool isInCommunicationDistance() {
    return (movingBehavior.currentDistance < GameEngine.conversationDistance);
  }

  void updatePlayerPosition(LatLng playerPosition) async {
    movingBehavior.updatePlayerPosition(playerPosition);

    if (movingBehavior.currentDistance < GameEngine.conversationDistance) {
      await GameEngine().registerApproach(this);
    }
  }
}

class MovingBehavior {
  bool isMoving;
  bool isFollowing;
  bool isLeading;
  //bool isWaiting;

  DateTime movementStartTime;

  LatLng currentBasePosition;
  LatLng toPosition;
  LatLng playerPosition = LatLng(51.5074, -0.1278); //London
  List<LatLng> path;
  double speedInKmh;
  double speedInms;
  static const followingDistance = 5.0;
  static const waitDistance = 75.0;
  static const continueDistance = 20.0;

  MovingBehavior({
    required this.currentBasePosition,
    required this.toPosition,
    required this.speedInKmh,
  }) : isMoving = false,
       isFollowing = false,
       isLeading = false,
       movementStartTime = DateTime.now(),
       path = [],
       speedInms = speedInKmh * 1000 / 3600;

  double get currentDistance {
    return Distance().as(LengthUnit.Meter, currentPosition, playerPosition);
  }

  LatLng _interpolatePosition(LatLng from, LatLng to, double distanceToTravel) {
    final totalDistance = Distance().as(LengthUnit.Meter, from, to);
    if (totalDistance == 0 || distanceToTravel >= totalDistance) return to;

    final fraction = distanceToTravel / totalDistance;
    final newLat = from.latitude + (to.latitude - from.latitude) * fraction;
    final newLng = from.longitude + (to.longitude - from.longitude) * fraction;
    return LatLng(newLat, newLng);
  }

  LatLng get currentPosition {
    if (!isMoving) return currentBasePosition;

    final now = DateTime.now();
    final timeDiffSeconds =
        now.difference(movementStartTime).inMilliseconds / 1000.0;
    final distanceToTravel = speedInms * timeDiffSeconds;
    final distance = const Distance().as(
      LengthUnit.Meter,
      currentBasePosition,
      toPosition,
    );

    //Ziel bereits erreicht
    if (distanceToTravel > distance) {
      currentBasePosition = toPosition;
      if (path.isNotEmpty) {
        toPosition = path.removeAt(0);
        movementStartTime = now;
        return currentPosition; //rekursiver Aufruf
      }
      isMoving = false;
      return currentBasePosition;
    }

    final interpolatedPosition = _interpolatePosition(
      currentBasePosition,
      toPosition,
      distanceToTravel,
    );

    //wenn npc nahe genug beim player ist bleibt er stehen
    if (isFollowing) {
      final distanceToPlayer = const Distance().as(
        LengthUnit.Meter,
        interpolatedPosition,
        playerPosition,
      );
      if (distanceToPlayer < followingDistance) {
        isMoving = false;
        currentBasePosition = interpolatedPosition;
        return interpolatedPosition;
      }
    }

    //Wenn Spieler zu weit weg ist, bleibt er stehen.
    if (isLeading) {
      final distanceToPlayer = const Distance().as(LengthUnit.Meter, interpolatedPosition, playerPosition);
      if (distanceToPlayer > waitDistance) {
        isMoving = false;
        currentBasePosition = interpolatedPosition;
        return interpolatedPosition;
      }
    }

    return interpolatedPosition;
  }

  moveTo(LatLng toPosition) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    this.toPosition = toPosition;
    this.path = [];
    isMoving = true;
    isFollowing = false;
    isLeading = false;
    movementStartTime = DateTime.now();
  }

  void moveAlong(List<LatLng> p) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    path = List.from(p);
    this.toPosition = path.removeAt(0);
    isMoving = true;
    isFollowing = false;
    isLeading = false;
    movementStartTime = DateTime.now();
  }

  void leadAlong(List<LatLng> p) {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    path = List.from(p);
    this.toPosition = path.removeAt(0);
    isMoving = true;
    isFollowing = false;
    isLeading = true;
    movementStartTime = DateTime.now();
  }

  void startFollowing() {
    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    this.toPosition = playerPosition;
    this.path = [];
    isFollowing = true;
    isMoving = true;
    isLeading = false;
    movementStartTime = DateTime.now();
  }

  void leadTo(LatLng toPosition) {

    if (isMoving) {
      currentBasePosition = currentPosition;
    }
    this.toPosition = toPosition;
    this.path = [];
    isFollowing = false;
    isLeading = true;
    movementStartTime = DateTime.now();

    // Prüfen ob er gleich starten darf
    final distanceToPlayer = Distance().as(LengthUnit.Meter, currentBasePosition, playerPosition);
    isMoving = distanceToPlayer < waitDistance;
  }

  void stopMoving() {
    currentBasePosition = currentPosition;
    isFollowing = false;
    isMoving = false;
    isLeading = false;
    this.path = [];
  }

  void spawn(double distance) {
    final random = Random();

    // Zufälliger Winkel (0–360 Grad in Radiant)
    final angle = random.nextDouble() * 2 * pi;

    // Umrechnung Meter → Grad
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng =
        metersPerDegreeLat * cos(playerPosition.latitude * pi / 180);

    final deltaLat = (distance * cos(angle)) / metersPerDegreeLat;
    final deltaLng = (distance * sin(angle)) / metersPerDegreeLng;

    currentBasePosition = LatLng(
      playerPosition.latitude + deltaLat,
      playerPosition.longitude + deltaLng,
    );
    isMoving = false;
    isFollowing = false;
    isLeading = false;
  }

  void updatePlayerPosition(LatLng pos) {
    playerPosition = pos;
    if (isFollowing) {
      if (currentDistance > followingDistance) {
        movementStartTime = DateTime.now();
        toPosition = playerPosition;
        isMoving = true;
      }
    }
    if (isLeading) {
      if (!isMoving && currentDistance < continueDistance) {
        movementStartTime = DateTime.now();
        isMoving = true;
      }
    }
  }
}
