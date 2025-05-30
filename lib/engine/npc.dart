import 'package:storytrail/actions/npc_action.dart';
import 'package:storytrail/engine/game_element.dart';
import 'package:storytrail/engine/game_engine.dart';
import 'package:storytrail/engine/moving_controller.dart';
import 'package:storytrail/engine/prompt.dart';
import 'package:storytrail/engine/story_line.dart';
import 'package:latlong2/latlong.dart';
import 'package:storytrail/engine/conversation.dart';

enum NPCIcon { unknown, identified, nearby, unknownNearby }

class Npc extends GameElement with HasPosition, HasGameState implements ProximityAware {
  final Prompt prompt;
  final String descriptiveName;
  final String? iconAsset;

  bool hasSomethingToSay = false;
  bool hasInteracted = false;

  List<NpcAction> actions = [];

  late Conversation currentConversation;

  late final NPCMovementController movementController;

  Npc({
    required super.id,
    required super.name,
    required this.descriptiveName,
    required super.imageAsset,
    required this.prompt,
    required super.position,
    required this.actions,
    required super.isVisible,
    required super.isRevealed,
    required speed, //in km/h
    required this.iconAsset,
  }){
    movementController = NPCMovementController(
      currentBasePosition: position,
      toPosition: position,
      speedInKmh: speed,
      onEnterRange: () => GameEngine().registerApproach(this),
      onExitRange: () => {},//print("Range lost."),
      getPlayerPosition: () => GameEngine().playerPosition,
    );
    currentConversation = Conversation(this);
    registerSelf();
  }

  static Future<Npc> fromJsonAsync(Map<String, dynamic> json) async {
    try {
      final promptFile = json['prompt'] as String;
      Prompt prompt = await Prompt.createPrompt(promptFile);
      final actionsJson = json['actions'] as List? ?? [];
      final actions = actionsJson.map((a) => NpcAction.fromJson(a)).toList();

      final LatLng position = StoryLine.positionFromJson(json);
      return Npc(
        id: json['id'],
        name: json['name'],
        descriptiveName : json['descriptiveName'],
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

  loadGameState(Map<String, dynamic> json) {
    isVisible = json['isVisible'] as bool;
    isRevealed = json['isRevealed'] as bool;
    hasSomethingToSay = json['hasSomethingToSay'] as bool;
    hasInteracted = json['hasInteracted'] as bool;
  }

  Map<String, dynamic> saveGameState() => {
    'id': id,
    'isVisible': isVisible,
    'isRevealed': isRevealed,
    'hasSomethingToSay': hasSomethingToSay,
    'hasInteracted': hasInteracted,
  };

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

  Future <void> talk(String repsondTo) async {
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
    return isRevealed ? name : descriptiveName;
  }

  LatLng get currentPosition {
    return movementController.currentPosition;
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

  @override
  void updateProximity(LatLng playerPosition) {
    movementController.updatePlayerProximity();
  }
}
