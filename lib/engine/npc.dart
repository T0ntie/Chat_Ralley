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

  final NPCMovementController movingController;

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
  }) :movingController = NPCMovementController(
         currentBasePosition: position,
         toPosition: position,
         speedInKmh: speed,
       )
  {
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
    movingController.spawn(distance);
  }


  void leadTo(LatLng toPosition) {
    movingController.leadTo(toPosition);
  }

  void moveTo(LatLng toPosition) {
    movingController.moveTo(toPosition);
  }

  void moveAlong(List<LatLng> path) {
    movingController.moveAlong(path);
  }

  void leadAlong(List<LatLng> path) {
    movingController.leadAlong(path);
  }

  void startFollowing() {
    movingController.startFollowing();
  }

  void stopMoving() {
    movingController.stopMoving();
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
    return movingController.currentDistance;
  }

  String get displayName {
    return isRevealed ? name : "Unbekannt";
  }

  LatLng get currentPosition {
    return movingController.currentPosition;
  }

  NPCIcon get icon {
    if (isVisible) {
      if (isRevealed) {
        if (isInCommunicationDistance()) {
          return NPCIcon.nearby;
        } else {
          return NPCIcon.identified;
        }
      } else {
        if (isInCommunicationDistance()) {
          return NPCIcon.unknownNearby;
        } else {
          return NPCIcon.unknown;
        }
      }
    }
    return NPCIcon.unknown;
  }

  bool isInCommunicationDistance() {
    return (movingController.currentDistance < GameEngine.conversationDistance);
  }

  void updatePlayerPosition(LatLng playerPosition) async {
    movingController.updatePlayerPosition(playerPosition);

    if (movingController.currentDistance < GameEngine.conversationDistance) {
      await GameEngine().registerApproach(this);
    }
  }
}