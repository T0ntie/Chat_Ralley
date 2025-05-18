import 'package:hello_world/actions/npc_action.dart';
import 'package:hello_world/engine/game_element.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'package:hello_world/engine/moving_behavior.dart';
import 'package:hello_world/engine/prompt.dart';
import 'package:hello_world/engine/story_line.dart';
import 'package:latlong2/latlong.dart';
import 'conversation.dart';

enum NPCIcon { unknown, identified, nearby, unknownNearby }

class Npc extends GameElement {
  final Prompt prompt;
  final String? iconAsset;

  bool hasSomethingToSay = false;

  List<NpcAction> actions = [];

  late Conversation currentConversation;

  late final NPCMovementController movementController;

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
  }){
    movementController = NPCMovementController(
      currentBasePosition: position,
      toPosition: position,
      speedInKmh: speed,
      onEnterRange: () => GameEngine().registerApproach(this),
      onExitRange: () => print("Range lost."),
      getPlayerPosition: () => GameEngine().playerPosition,
    );
    currentConversation = Conversation(this);
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
    movementController.spawn(distance);
  }

  void leadTo(LatLng toPosition) {
    movementController.leadTo(toPosition);
  }

  void moveTo(LatLng toPosition) {
    movementController.moveTo(toPosition);
  }

  void moveAlong(List<LatLng> path) {
    movementController.moveAlong(path);
  }

  void leadAlong(List<LatLng> path) {
    movementController.leadAlong(path);
  }

  void startFollowing() {
    movementController.startFollowing();
  }

  void stopMoving() {
    movementController.stopMoving();
  }

  Future<void> stopTalking() async {
    await currentConversation.finishConversation();
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
    return movementController.currentDistance;
  }

  String get displayName {
    return isRevealed ? name : "Unbekannt";
  }

  LatLng get currentPosition {
    return movementController.currentPosition;
  }

  void checkProximityToPlayer() {
    movementController.checkProximityToPlayer();
  }

  NPCIcon get icon {
    if (isVisible) {
      if (isRevealed) {
        if (isInCommunicationDistance) {
          return NPCIcon.nearby;
        } else {
          return NPCIcon.identified;
        }
      } else {
        if (isInCommunicationDistance) {
          return NPCIcon.unknownNearby;
        } else {
          return NPCIcon.unknown;
        }
      }
    }
    return NPCIcon.unknown;
  }

  bool get isInCommunicationDistance => movementController.isInCommunicationDistance;

/*
  void updatePlayerPosition(LatLng playerPosition) async {
    movementController.updatePlayerPosition(playerPosition);
  }
*/
}
